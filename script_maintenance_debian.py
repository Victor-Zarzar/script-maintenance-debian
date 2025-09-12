import os
import subprocess

def run_command(command):
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Erro ao executar: {command}\n{e}")

def update_system():
    print("🔄 Atualizando pacotes do sistema...")
    try:
        # Tenta atualizar fontes primeiro
        subprocess.run("sudo apt update", shell=True, check=True)
        # Se conseguir atualizar fontes, faz upgrade
        run_command("sudo apt upgrade -y")
    except subprocess.CalledProcessError as e:
        print(f"⚠️ Aviso: Problema ao atualizar fontes de pacotes (código {e.returncode})")
        print("Continuando com outras tarefas de manutenção...")
        # Tenta modernizar as fontes se disponível (Ubuntu mais recente)
        try:
            subprocess.run("sudo apt modernize-sources", shell=True, check=False)
            print("ℹ️ Tentativa de modernizar fontes realizada.")
        except:
            print("ℹ️ Comando modernize-sources não disponível.")

def remove_orphans():
    print("🧹 Removendo pacotes órfãos...")
    run_command("sudo apt autoremove -y")
    run_command("sudo apt autoclean")

def clean_package_cache():
    print("🗂 Limpando cache do APT...")
    run_command("sudo apt clean")
    run_command("sudo apt autoclean")

def remove_unnecessary_packages():
    print("🗑 Removendo dependências desnecessárias...")
    run_command("sudo apt autoremove --purge -y")

def clean_snap_packages():
    print("📦 Limpando versões antigas do Snap...")
    try:
        # Lista snaps instalados e remove versões antigas
        result = subprocess.run("snap list --all", shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            run_command("sudo snap set system refresh.retain=2")
            # Script para remover versões antigas do snap
            snap_cleanup = '''
            #!/bin/bash
            LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
            while read snapname revision; do
                sudo snap remove "$snapname" --revision="$revision"
            done
            '''
            run_command(f"echo '{snap_cleanup}' | sudo bash")
        else:
            print("Snap não está instalado ou não há snaps para limpar.")
    except Exception:
        print("Erro ao limpar snaps ou snap não instalado.")

def clean_flatpak():
    print("📱 Limpando Flatpak...")
    try:
        result = subprocess.run("which flatpak", shell=True, capture_output=True)
        if result.returncode == 0:
            run_command("flatpak uninstall --unused -y")
            run_command("flatpak repair")
        else:
            print("Flatpak não está instalado.")
    except Exception:
        print("Erro ao limpar Flatpak ou não está instalado.")

def clean_docker():
    print("🐳 Limpando imagens, containers e volumes não usados do Docker...")
    try:
        result = subprocess.run("which docker", shell=True, capture_output=True)
        if result.returncode == 0:
            run_command("docker system prune -af --volumes")
        else:
            print("Docker não está instalado.")
    except Exception:
        print("Docker não está instalado ou erro ao executar limpeza.")

def clean_logs():
    print("🗂 Limpando logs antigos...")
    run_command("sudo journalctl --vacuum-time=7d")
    run_command("sudo logrotate -f /etc/logrotate.conf")

def clean_user_caches():
    print("🧹 Limpando caches gerais...")
    # Limpa cache do usuário atual
    os.system("rm -rf ~/.cache/*")
    # Limpa thumbnails
    os.system("rm -rf ~/.thumbnails/*")
    # Limpa cache do sistema (requer sudo)
    os.system("sudo rm -rf /var/cache/apt/archives/*.deb")
    os.system("sudo rm -rf /tmp/*")

def clean_old_kernels():
    print("🔧 Removendo kernels antigos (mantendo os 2 mais recentes)...")
    try:
        # Lista kernels instalados e remove os antigos, mantendo atual + 1 backup
        kernel_cleanup = '''
        dpkg --list | grep linux-image | awk '{ print $2 }' | sort -V | head -n -2 | xargs sudo apt-get -y purge
        dpkg --list | grep linux-headers | awk '{ print $2 }' | sort -V | head -n -2 | xargs sudo apt-get -y purge
        '''
        run_command(kernel_cleanup)
    except Exception:
        print("Erro ao remover kernels antigos ou nenhum kernel antigo encontrado.")

def update_locate_database():
    print("🔍 Atualizando banco de dados do locate...")
    run_command("sudo updatedb")

def fix_broken_packages():
    print("🔧 Verificando e corrigindo pacotes quebrados...")
    run_command("sudo apt --fix-broken install -y")
    run_command("sudo dpkg --configure -a")

if __name__ == "__main__":
    print("🚀 Iniciando manutenção do Ubuntu/Debian...\n")
    
    update_system()
    fix_broken_packages()
    remove_orphans()
    remove_unnecessary_packages()
    clean_package_cache()
    clean_snap_packages()
    clean_flatpak()
    clean_docker()
    clean_old_kernels()
    clean_logs()
    clean_user_caches()
    update_locate_database()
    
    print("\n✅ Manutenção do Ubuntu/Debian concluída!")
    print("💡 Recomenda-se reiniciar o sistema se kernels foram atualizados.")