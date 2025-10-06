import os
import subprocess
import shutil
from pathlib import Path

def run_command(command, use_sudo=False, ignore_errors=False, input_text=None):
    """Executa comando com tratamento de erro"""
    try:
        if use_sudo:
            command = f"sudo {command}"
        
        if input_text:
            result = subprocess.run(
                command, 
                shell=True, 
                check=True, 
                capture_output=True, 
                text=True,
                input=input_text
            )
        else:
            result = subprocess.run(
                command, 
                shell=True, 
                check=True, 
                capture_output=True, 
                text=True,
                timeout=30
            )
        return True, result.stdout
    except subprocess.TimeoutExpired:
        if not ignore_errors:
            print(f"  ⏱️ Timeout ao executar: {command}")
        return False, "Timeout"
    except subprocess.CalledProcessError as e:
        if not ignore_errors:
            print(f"  ⚠️ Erro ao executar: {command}\n  {e}")
        return False, e.stderr
    except Exception as e:
        if not ignore_errors:
            print(f"  ⚠️ Erro inesperado: {e}")
        return False, str(e)

def update_system():
    """Atualiza pacotes do sistema"""
    print("🔄 Atualizando pacotes do sistema...")
    
    success, _ = run_command("apt update", use_sudo=True, ignore_errors=True)
    if success:
        print("  ✅ Fontes atualizadas com sucesso")
        run_command("apt upgrade -y", use_sudo=True)
        run_command("apt dist-upgrade -y", use_sudo=True, ignore_errors=True)
    else:
        print("  ⚠️ Problema ao atualizar fontes de pacotes")
        print("  ℹ️ Tentando modernizar fontes...")
        run_command("apt modernize-sources", use_sudo=True, ignore_errors=True)

def fix_broken_packages():
    """Verifica e corrige pacotes quebrados"""
    print("🔧 Verificando e corrigindo pacotes quebrados...")
    run_command("apt --fix-broken install -y", use_sudo=True)
    run_command("dpkg --configure -a", use_sudo=True)
    run_command("apt -f install -y", use_sudo=True, ignore_errors=True)

def remove_orphans():
    """Remove pacotes órfãos e desnecessários"""
    print("🧹 Removendo pacotes órfãos e dependências desnecessárias...")
    run_command("apt autoremove -y", use_sudo=True)
    run_command("apt autoremove --purge -y", use_sudo=True)
    run_command("apt autoclean", use_sudo=True)

def clean_package_cache():
    """Limpa cache de pacotes APT"""
    print("🗂 Limpando cache do APT...")
    
    cache_path = "/var/cache/apt/archives"
    if os.path.exists(cache_path):
        size = get_folder_size(cache_path)
        if size > 0:
            print(f"  📦 Cache atual: {format_bytes(size)}")
    
    run_command("apt clean", use_sudo=True)
    run_command("apt autoclean", use_sudo=True)
    
    run_command("rm -rf /var/cache/apt/archives/*.deb", use_sudo=True, ignore_errors=True)
    run_command("rm -rf /var/cache/apt/archives/partial/*", use_sudo=True, ignore_errors=True)
    
    print("  ✅ Cache do APT limpo")

def clean_snap_packages():
    """Limpa versões antigas do Snap"""
    print("📦 Limpando versões antigas do Snap...")
    
    success, _ = run_command("which snap", ignore_errors=True)
    if not success:
        print("  ℹ️ Snap não está instalado")
        return
    
    run_command("snap set system refresh.retain=2", use_sudo=True, ignore_errors=True)
    
    snap_cleanup = """
    LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" 2>/dev/null
    done
    """
    success, _ = run_command(snap_cleanup, ignore_errors=True)
    if success:
        print("  ✅ Versões antigas do Snap removidas")

def clean_flatpak():
    """Limpa pacotes não usados do Flatpak"""
    print("📱 Limpando Flatpak...")
    
    success, _ = run_command("which flatpak", ignore_errors=True)
    if not success:
        print("  ℹ️ Flatpak não está instalado")
        return
    
    run_command("flatpak uninstall --unused -y", ignore_errors=True)
    run_command("flatpak repair", ignore_errors=True)
    run_command("flatpak uninstall --delete-data -y", ignore_errors=True)
    
    print("  ✅ Flatpak otimizado")

def clean_nvm_npm_cache():
    """Limpa cache do nvm e npm"""
    print("📦 Limpando cache do nvm/npm...")
    
    nvm_dir = os.path.expanduser("~/.nvm")
    if os.path.exists(nvm_dir):
        npm_cache_path = os.path.expanduser("~/.npm")
        if os.path.exists(npm_cache_path):
            size = get_folder_size(npm_cache_path)
            if size > 0:
                print(f"  📊 Tamanho do cache npm: {format_bytes(size)}")
            try:
                shutil.rmtree(npm_cache_path, ignore_errors=True)
                print("  ✅ Cache npm removido")
            except Exception as e:
                print(f"  ⚠️ Erro ao remover cache npm: {e}")
        
        nvm_cache_paths = [
            "~/.nvm/.cache"
        ]
        
        for path in nvm_cache_paths:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path):
                try:
                    size = get_folder_size(expanded_path)
                    shutil.rmtree(expanded_path, ignore_errors=True)
                    if size > 0:
                        print(f"  ✅ Removido {format_bytes(size)}: {path}")
                except Exception:
                    pass
        
        success, _ = run_command("npm cache clean --force", ignore_errors=True)
        if success:
            run_command("npm cache verify", ignore_errors=True)
        
        print("  ✅ Cache do nvm/npm limpo")
    else:
        print("  ℹ️ nvm não encontrado, pulando...")

def clean_pnpm_cache():
    """Limpa cache do pnpm"""
    print("📦 Limpando cache do pnpm...")
    
    success, _ = run_command("which pnpm", ignore_errors=True)
    if success:
        pnpm_paths = [
            "~/.pnpm-store",
            "~/.local/share/pnpm/store"
        ]
        
        total_size = 0
        for path in pnpm_paths:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path):
                size = get_folder_size(expanded_path)
                total_size += size
        
        if total_size > 0:
            print(f"  📊 Tamanho do cache pnpm: {format_bytes(total_size)}")
        
        run_command("pnpm store prune", ignore_errors=True)
        print("  ✅ Cache do pnpm limpo")
    else:
        print("  ℹ️ pnpm não encontrado, pulando...")

def clean_dart_flutter_cache():
    """Limpa cache do Dart, Flutter e FVM"""
    print("🎯 Limpando cache do Dart/Flutter/FVM...")
    
    success, _ = run_command("which flutter", ignore_errors=True)
    if success:
        flutter_cache_path = os.path.expanduser("~/.flutter")
        if os.path.exists(flutter_cache_path):
            size = get_folder_size(flutter_cache_path)
            if size > 0:
                print(f"  📊 Tamanho do cache Flutter: {format_bytes(size)}")
        
        flutter_clean_paths = [
            "~/.flutter-devtools",
            "~/.flutter/bin/cache"
        ]
        
        for path in flutter_clean_paths:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path):
                try:
                    shutil.rmtree(expanded_path, ignore_errors=True)
                except Exception:
                    pass
        
        print("  🔄 Limpando pub cache...")
        run_command("echo 'y' | flutter pub cache clean", ignore_errors=True)
        
        run_command("flutter pub cache repair", ignore_errors=True)
        
        print("  ✅ Cache do Flutter limpo")
    else:
        print("  ℹ️ Flutter não encontrado")
    
    dart_cache_paths = [
        "~/.pub-cache/hosted/*/cache",
        "~/.dart",
        "~/.dartServer"
    ]
    
    total_dart_size = 0
    for path in dart_cache_paths:
        expanded_path = os.path.expanduser(path)
        if "*" in path:
            run_command(f"find {os.path.dirname(os.path.expanduser(path))} -path '*cache' -type d -exec rm -rf {{}} + 2>/dev/null", ignore_errors=True)
        elif os.path.exists(expanded_path):
            size = get_folder_size(expanded_path)
            total_dart_size += size
            try:
                shutil.rmtree(expanded_path, ignore_errors=True)
            except Exception:
                pass
    
    if total_dart_size > 0:
        print(f"  📊 Cache Dart removido: {format_bytes(total_dart_size)}")
    
    success, _ = run_command("which dart", ignore_errors=True)
    if success:
        run_command("dart pub cache repair", ignore_errors=True)
        print("  ✅ Cache do Dart limpo")
    
    success, _ = run_command("which fvm", ignore_errors=True)
    if success:
        fvm_cache_path = os.path.expanduser("~/fvm/versions")
        if os.path.exists(fvm_cache_path):
            size = get_folder_size(fvm_cache_path)
            if size > 0:
                print(f"  📊 Tamanho do cache FVM: {format_bytes(size)}")
        
        print("  💡 FVM: use 'fvm remove <version>' para remover versões específicas")
        print("  ✅ FVM verificado")
    else:
        print("  ℹ️ FVM não encontrado")

def clean_docker():
    """Limpa recursos não usados do Docker"""
    print("🐳 Limpando Docker...")
    
    success, _ = run_command("which docker", ignore_errors=True)
    if not success:
        print("  ℹ️ Docker não está instalado")
        return
    
    run_command("docker stop $(docker ps -q) 2>/dev/null", ignore_errors=True)
    run_command("docker system prune -af --volumes", ignore_errors=True)
    run_command("docker builder prune -af", ignore_errors=True)
    run_command("docker image prune -af", ignore_errors=True)
    
    print("  ✅ Docker limpo")

def clean_old_kernels():
    """Remove kernels antigos mantendo os 2 mais recentes"""
    print("🔧 Removendo kernels antigos (mantendo os 2 mais recentes)...")
    
    success, output = run_command("uname -r", ignore_errors=True)
    if success:
        current_kernel = output.strip()
        print(f"  ℹ️ Kernel atual: {current_kernel}")
    
    kernel_cleanup = """
    dpkg --list | grep -E 'linux-image-[0-9]' | awk '{ print $2 }' | sort -V | head -n -2 | xargs sudo apt-get -y purge 2>/dev/null
    dpkg --list | grep -E 'linux-headers-[0-9]' | awk '{ print $2 }' | sort -V | head -n -2 | xargs sudo apt-get -y purge 2>/dev/null
    dpkg --list | grep -E 'linux-modules-[0-9]' | awk '{ print $2 }' | sort -V | head -n -2 | xargs sudo apt-get -y purge 2>/dev/null
    """
    run_command(kernel_cleanup, ignore_errors=True)
    run_command("update-grub", use_sudo=True, ignore_errors=True)
    
    print("  ✅ Kernels antigos removidos")

def clean_logs():
    """Limpa logs antigos do sistema"""
    print("🗂 Limpando logs antigos...")
    
    run_command("journalctl --vacuum-time=7d", use_sudo=True)
    run_command("journalctl --vacuum-size=100M", use_sudo=True, ignore_errors=True)
    
    run_command("logrotate -f /etc/logrotate.conf", use_sudo=True, ignore_errors=True)
    
    log_paths = [
        "/var/log/*.log",
        "/var/log/*.gz",
        "/var/log/*.1",
        "/var/log/*.old"
    ]
    
    for pattern in log_paths:
        run_command(f"find /var/log -type f -name '{os.path.basename(pattern)}' -mtime +7 -delete", use_sudo=True, ignore_errors=True)
    
    print("  ✅ Logs limpos")

def clean_user_caches():
    """Limpa caches de usuário"""
    print("🧹 Limpando caches de usuário...")
    
    total_cleaned = 0
    
    cache_paths = [
        "~/.cache",
        "~/.thumbnails",
        "~/.local/share/Trash",
        "~/.mozilla/firefox/*/cache2",
        "~/.cache/google-chrome",
        "~/.cache/chromium",
        "~/.config/Code/Cache",
        "~/.config/Code/CachedData",
        "~/.vscode/extensions/*/node_modules"
    ]
    
    for path in cache_paths:
        expanded_path = os.path.expanduser(path)
        
        if "*" in expanded_path:
            run_command(f"rm -rf {expanded_path}", ignore_errors=True)
        elif os.path.exists(expanded_path):
            try:
                size = get_folder_size(expanded_path)
                total_cleaned += size
                
                if os.path.isdir(expanded_path):
                    if ".cache" in expanded_path and expanded_path == os.path.expanduser("~/.cache"):
                        for item in os.listdir(expanded_path):
                            item_path = os.path.join(expanded_path, item)
                            try:
                                if os.path.isdir(item_path):
                                    shutil.rmtree(item_path, ignore_errors=True)
                                else:
                                    os.remove(item_path)
                            except:
                                pass
                    else:
                        shutil.rmtree(expanded_path, ignore_errors=True)
                else:
                    os.remove(expanded_path)
            except Exception:
                pass
    
    run_command("rm -rf /tmp/*", use_sudo=True, ignore_errors=True)
    run_command("rm -rf /var/tmp/*", use_sudo=True, ignore_errors=True)
    
    if total_cleaned > 0:
        print(f"  ✅ Total de cache limpo: {format_bytes(total_cleaned)}")

def clean_system_temp():
    """Limpa arquivos temporários do sistema"""
    print("🗑 Limpando arquivos temporários do sistema...")
    
    temp_paths = [
        "/tmp",
        "/var/tmp",
        "/var/cache/apt/archives",
        "/var/cache/debconf"
    ]
    
    for path in temp_paths:
        if os.path.exists(path):
            run_command(f"find {path} -type f -atime +7 -delete", use_sudo=True, ignore_errors=True)

def optimize_databases():
    """Otimiza bancos de dados do sistema"""
    print("💾 Otimizando bancos de dados do sistema...")
    
    run_command("mandb", use_sudo=True, ignore_errors=True)
    
    run_command("updatedb", use_sudo=True, ignore_errors=True)
    
    if os.path.exists("/etc/apt/apt.conf.d/20auto-upgrades"):
        run_command("apt-config dump", use_sudo=True, ignore_errors=True)
    
    print("  ✅ Bancos de dados otimizados")

def clean_pip_cache():
    """Limpa cache do pip"""
    print("🐍 Limpando cache do pip...")
    
    success, _ = run_command("which pip3", ignore_errors=True)
    if success:
        pip_cache = os.path.expanduser("~/.cache/pip")
        if os.path.exists(pip_cache):
            size = get_folder_size(pip_cache)
            run_command("pip3 cache purge", ignore_errors=True)
            if size > 0:
                print(f"  ✅ Cache do pip limpo: {format_bytes(size)}")
    else:
        print("  ℹ️ pip não está instalado")

def verify_system_health():
    """Verifica saúde do sistema"""
    print("🏥 Verificando saúde do sistema...")
    
    run_command("apt check", use_sudo=True, ignore_errors=True)
    
    success, output = run_command("systemctl --failed", ignore_errors=True)
    if success and "0 loaded units listed" not in output:
        print("  ⚠️ Existem serviços com falha:")
        print(output)
    else:
        print("  ✅ Todos os serviços estão funcionando")

def get_folder_size(folder_path):
    """Calcula tamanho de uma pasta"""
    total_size = 0
    try:
        for dirpath, dirnames, filenames in os.walk(folder_path):
            for filename in filenames:
                filepath = os.path.join(dirpath, filename)
                try:
                    total_size += os.path.getsize(filepath)
                except (OSError, IOError):
                    pass
    except Exception:
        pass
    return total_size

def format_bytes(bytes_size):
    """Formata bytes em formato legível"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_size < 1024.0:
            return f"{bytes_size:.1f} {unit}"
        bytes_size /= 1024.0
    return f"{bytes_size:.1f} PB"

def show_disk_usage():
    """Mostra uso do disco"""
    success, output = run_command("df -h / | tail -1 | awk '{print $4}'", ignore_errors=True)
    if success:
        return output.strip()
    return "N/A"

if __name__ == "__main__":
    print("🚀 Iniciando manutenção avançada do Ubuntu/Debian...\n")
    
    initial_space = show_disk_usage()
    print(f"💾 Espaço livre inicial: {initial_space}\n")
    
    update_system()
    fix_broken_packages()
    remove_orphans()
    clean_package_cache()
    clean_snap_packages()
    clean_flatpak()
    clean_nvm_npm_cache()
    clean_pnpm_cache()
    clean_dart_flutter_cache()
    clean_docker()
    clean_old_kernels()
    clean_logs()
    clean_user_caches()
    clean_system_temp()
    clean_pip_cache()
    optimize_databases()
    verify_system_health()
    
    final_space = show_disk_usage()
    print(f"\n💾 Espaço livre final: {final_space}")
    print("\n✅ Manutenção avançada do Ubuntu/Debian concluída!")
    print("💡 Recomenda-se reiniciar o sistema se kernels foram atualizados.")
    
    print("\n🔍 Para verificação adicional, execute:")
    print("   sudo fsck -fn /")
    print("   sudo apt list --upgradable")
    print("   sudo systemctl --failed")