#!/bin/bash

# ============================================
# Advanced Debian/Ubuntu Maintenance Script
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global variables
TOTAL_CLEANED=0
LOG_FILE="$HOME/debian_maintenance_$(date +%Y%m%d_%H%M%S).log"

# ============================================
# Helper Functions
# ============================================

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Advanced Debian/Ubuntu Maintenance  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${PURPLE}$1${NC}"
    echo "────────────────────────────────────────"
}

print_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

get_folder_size() {
    local path="$1"
    if [ -d "$path" ]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}'
    else
        echo "0"
    fi
}

format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes/1073741824" | bc) GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc) MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes/1024" | bc) KB"
    else
        echo "${bytes} B"
    fi
}

show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%%${NC}" $percentage
}

get_disk_usage() {
    df -h / | tail -1 | awk '{print $4}'
}

# ============================================
# Maintenance Functions
# ============================================

update_system() {
    print_section "Updating System Packages"
    
    print_info "Updating package sources..."
    sudo apt update &>/dev/null && print_success "Sources updated"
    
    print_info "Upgrading packages..."
    sudo apt upgrade -y &>/dev/null && print_success "Packages upgraded"
    
    print_info "Performing distribution upgrade..."
    sudo apt dist-upgrade -y &>/dev/null && print_success "Distribution upgraded"
    
    log_action "System packages updated"
}

fix_broken_packages() {
    print_section "Fixing Broken Packages"
    
    print_info "Fixing broken installations..."
    sudo apt --fix-broken install -y &>/dev/null
    
    print_info "Configuring pending packages..."
    sudo dpkg --configure -a &>/dev/null
    
    print_info "Running additional fixes..."
    sudo apt -f install -y &>/dev/null
    
    print_success "Package fixes completed"
    log_action "Broken packages fixed"
}

remove_orphans() {
    print_section "Removing Orphaned Packages"
    
    print_info "Removing unnecessary packages..."
    sudo apt autoremove -y &>/dev/null && print_success "Orphaned packages removed"
    
    print_info "Purging removed packages..."
    sudo apt autoremove --purge -y &>/dev/null
    
    print_info "Cleaning up..."
    sudo apt autoclean &>/dev/null
    
    log_action "Orphaned packages removed"
}

clean_package_cache() {
    print_section "Cleaning APT Cache"
    
    local cache_path="/var/cache/apt/archives"
    if [ -d "$cache_path" ]; then
        local size=$(get_folder_size "$cache_path")
        if [ "$size" -gt 0 ]; then
            print_info "Current cache: $(format_bytes $((size * 1024)))"
        fi
    fi
    
    sudo apt clean &>/dev/null
    sudo apt autoclean &>/dev/null
    
    sudo rm -rf /var/cache/apt/archives/*.deb 2>/dev/null
    sudo rm -rf /var/cache/apt/archives/partial/* 2>/dev/null
    
    print_success "APT cache cleaned"
    log_action "APT cache cleaned"
}

clean_snap_packages() {
    print_section "Cleaning Old Snap Versions"
    
    if ! command -v snap &> /dev/null; then
        print_info "Snap not installed"
        return
    fi
    
    print_info "Setting retention policy..."
    sudo snap set system refresh.retain=2 &>/dev/null
    
    print_info "Removing disabled snaps..."
    LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' | \
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision" &>/dev/null
    done
    
    print_success "Old snap versions removed"
    log_action "Snap packages cleaned"
}

clean_flatpak() {
    print_section "Cleaning Flatpak"
    
    if ! command -v flatpak &> /dev/null; then
        print_info "Flatpak not installed"
        return
    fi
    
    print_info "Removing unused runtimes..."
    flatpak uninstall --unused -y &>/dev/null
    
    print_info "Repairing flatpak..."
    flatpak repair &>/dev/null
    
    print_success "Flatpak optimized"
    log_action "Flatpak cleaned"
}

clean_nvm_npm() {
    print_section "Cleaning NPM/NVM Cache"
    
    if [ -d "$HOME/.nvm" ]; then
        local npm_cache="$HOME/.npm"
        if [ -d "$npm_cache" ]; then
            local size=$(get_folder_size "$npm_cache")
            rm -rf "$npm_cache" 2>/dev/null && \
                print_success "npm cache: $(format_bytes $((size * 1024)))"
            TOTAL_CLEANED=$((TOTAL_CLEANED + size))
        fi
        
        if command -v npm &> /dev/null; then
            npm cache clean --force &>/dev/null && print_success "npm cache cleaned"
            npm cache verify &>/dev/null
        fi
    else
        print_info "NVM not found"
    fi
    
    log_action "NPM/NVM cleaned"
}

clean_pnpm() {
    print_section "Cleaning PNPM Cache"
    
    if command -v pnpm &> /dev/null; then
        local paths=(
            "$HOME/.pnpm-store"
            "$HOME/.local/share/pnpm/store"
        )
        
        for path in "${paths[@]}"; do
            if [ -d "$path" ]; then
                local size=$(get_folder_size "$path")
                TOTAL_CLEANED=$((TOTAL_CLEANED + size))
            fi
        done
        
        pnpm store prune &>/dev/null && print_success "pnpm store cleaned"
    else
        print_info "PNPM not found"
    fi
    
    log_action "PNPM cleaned"
}

clean_flutter_dart() {
    print_section "Cleaning Flutter/Dart/FVM Cache"
    
    if command -v flutter &> /dev/null; then
        local paths=(
            "$HOME/.flutter-devtools"
            "$HOME/.flutter/bin/cache"
        )
        
        for path in "${paths[@]}"; do
            if [ -d "$path" ]; then
                local size=$(get_folder_size "$path")
                rm -rf "$path" 2>/dev/null
                TOTAL_CLEANED=$((TOTAL_CLEANED + size))
            fi
        done
        
        print_info "Cleaning pub cache..."
        echo 'y' | flutter pub cache clean &>/dev/null
        flutter pub cache repair &>/dev/null && print_success "Flutter pub cache cleaned"
    else
        print_info "Flutter not found"
    fi
    
    if command -v dart &> /dev/null; then
        dart pub cache repair &>/dev/null && print_success "Dart pub cache repaired"
    fi
    
    if command -v fvm &> /dev/null; then
        print_info "FVM found - use 'fvm remove <version>' for specific versions"
    fi
    
    log_action "Flutter/Dart/FVM cleaned"
}

clean_docker() {
    print_section "Cleaning Docker"
    
    if ! command -v docker &> /dev/null; then
        print_info "Docker not installed"
        return
    fi
    
    print_info "Stopping containers..."
    docker stop $(docker ps -q) 2>/dev/null
    
    print_info "Cleaning Docker system..."
    docker system prune -af --volumes &>/dev/null && print_success "Docker cleaned"
    
    docker builder prune -af &>/dev/null && print_success "Build cache cleaned"
    
    log_action "Docker cleaned"
}

clean_old_kernels() {
    print_section "Removing Old Kernels (keeping latest 2)"
    
    local current_kernel=$(uname -r)
    print_info "Current kernel: $current_kernel"
    
    print_info "Removing old kernel images..."
    dpkg --list | grep -E 'linux-image-[0-9]' | awk '{ print $2 }' | sort -V | head -n -2 | \
        xargs sudo apt-get -y purge &>/dev/null
    
    print_info "Removing old kernel headers..."
    dpkg --list | grep -E 'linux-headers-[0-9]' | awk '{ print $2 }' | sort -V | head -n -2 | \
        xargs sudo apt-get -y purge &>/dev/null
    
    print_info "Updating GRUB..."
    sudo update-grub &>/dev/null
    
    print_success "Old kernels removed"
    log_action "Old kernels removed"
}

clean_logs() {
    print_section "Cleaning Old Logs"
    
    print_info "Vacuuming journal logs..."
    sudo journalctl --vacuum-time=7d &>/dev/null
    sudo journalctl --vacuum-size=100M &>/dev/null
    
    print_info "Rotating logs..."
    sudo logrotate -f /etc/logrotate.conf &>/dev/null
    
    print_info "Removing old log files..."
    sudo find /var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    sudo find /var/log -type f -name "*.gz" -mtime +7 -delete 2>/dev/null
    sudo find /var/log -type f -name "*.1" -mtime +7 -delete 2>/dev/null
    sudo find /var/log -type f -name "*.old" -mtime +7 -delete 2>/dev/null
    
    print_success "Logs cleaned"
    log_action "Logs cleaned"
}

clean_user_caches() {
    print_section "Cleaning User Caches"
    
    local cache_paths=(
        "$HOME/.cache"
        "$HOME/.thumbnails"
        "$HOME/.local/share/Trash"
    )
    
    for path in "${cache_paths[@]}"; do
        if [ -d "$path" ]; then
            local size=$(get_folder_size "$path")
            rm -rf "$path"/* 2>/dev/null
            if [ "$size" -gt 0 ]; then
                print_success "Cleaned: $(format_bytes $((size * 1024)))"
                TOTAL_CLEANED=$((TOTAL_CLEANED + size))
            fi
        fi
    done
    
    print_info "Cleaning browser caches..."
    rm -rf "$HOME/.mozilla/firefox/*/cache2" 2>/dev/null
    rm -rf "$HOME/.cache/google-chrome" 2>/dev/null
    rm -rf "$HOME/.cache/chromium" 2>/dev/null
    
    print_info "Cleaning VS Code cache..."
    rm -rf "$HOME/.config/Code/Cache" 2>/dev/null
    rm -rf "$HOME/.config/Code/CachedData" 2>/dev/null
    
    print_success "User caches cleaned"
    log_action "User caches cleaned"
}

clean_system_temp() {
    print_section "Cleaning System Temporary Files"
    
    print_info "Cleaning /tmp..."
    sudo rm -rf /tmp/* 2>/dev/null
    
    print_info "Cleaning /var/tmp..."
    sudo rm -rf /var/tmp/* 2>/dev/null
    
    print_info "Cleaning old temporary files..."
    sudo find /tmp -type f -atime +7 -delete 2>/dev/null
    sudo find /var/tmp -type f -atime +7 -delete 2>/dev/null
    
    print_success "Temporary files cleaned"
    log_action "Temporary files cleaned"
}

clean_pip_cache() {
    print_section "Cleaning Python PIP Cache"
    
    if command -v pip3 &> /dev/null; then
        local pip_cache="$HOME/.cache/pip"
        if [ -d "$pip_cache" ]; then
            local size=$(get_folder_size "$pip_cache")
            pip3 cache purge &>/dev/null
            if [ "$size" -gt 0 ]; then
                print_success "PIP cache cleaned: $(format_bytes $((size * 1024)))"
            fi
        fi
    else
        print_info "pip3 not installed"
    fi
    
    log_action "PIP cache cleaned"
}

optimize_databases() {
    print_section "Optimizing System Databases"
    
    print_info "Updating man database..."
    sudo mandb &>/dev/null
    
    print_info "Updating locate database..."
    sudo updatedb &>/dev/null
    
    print_success "Databases optimized"
    log_action "Databases optimized"
}

verify_system_health() {
    print_section "Verifying System Health"
    
    print_info "Checking for broken packages..."
    sudo apt check &>/dev/null && print_success "No broken packages found"
    
    print_info "Checking failed services..."
    local failed=$(systemctl --failed --no-pager 2>/dev/null | grep -c "loaded units listed")
    if [ "$failed" -eq 0 ]; then
        print_success "All services running normally"
    else
        print_warning "Some services have failed - check with: systemctl --failed"
    fi
    
    log_action "System health verified"
}

# ============================================
# Interactive Menu
# ============================================

show_menu() {
    clear
    print_header
    echo -e "${YELLOW}Current free space: $(get_disk_usage)${NC}"
    echo ""
    echo "1)  Run complete maintenance"
    echo "2)  Update system packages"
    echo "3)  Fix broken packages"
    echo "4)  Remove orphaned packages"
    echo "5)  Clean APT cache"
    echo "6)  Clean Snap packages"
    echo "7)  Clean Flatpak"
    echo "8)  Clean NPM/NVM"
    echo "9)  Clean PNPM"
    echo "10) Clean Flutter/Dart/FVM"
    echo "11) Clean Docker"
    echo "12) Remove old kernels"
    echo "13) Clean logs"
    echo "14) Clean user caches"
    echo "15) Clean temporary files"
    echo "16) Clean PIP cache"
    echo "17) Optimize databases"
    echo "18) Verify system health"
    echo "19) View action log"
    echo "0)  Exit"
    echo ""
    echo -n "Choose an option: "
}

run_full_maintenance() {
    local initial_space=$(get_disk_usage)
    
    print_header
    echo -e "${YELLOW}Initial free space: $initial_space${NC}\n"
    
    update_system
    fix_broken_packages
    remove_orphans
    clean_package_cache
    clean_snap_packages
    clean_flatpak
    clean_nvm_npm
    clean_pnpm
    clean_flutter_dart
    clean_docker
    clean_old_kernels
    clean_logs
    clean_user_caches
    clean_system_temp
    clean_pip_cache
    optimize_databases
    verify_system_health
    
    local final_space=$(get_disk_usage)
    
    echo ""
    print_section "Maintenance Summary"
    echo -e "${GREEN}Initial free space:${NC} $initial_space"
    echo -e "${GREEN}Final free space:${NC}   $final_space"
    echo -e "${GREEN}Total cleaned:${NC}      $(format_bytes $((TOTAL_CLEANED * 1024)))"
    echo ""
    print_success "Maintenance complete!"
    print_warning "System restart recommended if kernels were updated"
    echo ""
    
    log_action "Complete maintenance executed - Total: $(format_bytes $((TOTAL_CLEANED * 1024)))"
}

# ============================================
# Main Loop
# ============================================

main() {
    # Check if Debian/Ubuntu
    if [ ! -f /etc/debian_version ]; then
        print_error "This script is for Debian/Ubuntu systems only!"
        exit 1
    fi
    
    # Create log file
    touch "$LOG_FILE"
    log_action "Starting maintenance script"
    
    while true; do
        show_menu
        read -r option
        
        case $option in
            1) run_full_maintenance ;;
            2) update_system ;;
            3) fix_broken_packages ;;
            4) remove_orphans ;;
            5) clean_package_cache ;;
            6) clean_snap_packages ;;
            7) clean_flatpak ;;
            8) clean_nvm_npm ;;
            9) clean_pnpm ;;
            10) clean_flutter_dart ;;
            11) clean_docker ;;
            12) clean_old_kernels ;;
            13) clean_logs ;;
            14) clean_user_caches ;;
            15) clean_system_temp ;;
            16) clean_pip_cache ;;
            17) optimize_databases ;;
            18) verify_system_health ;;
            19) cat "$LOG_FILE" | less ;;
            0) 
                print_success "Goodbye!"
                log_action "Script finished"
                exit 0
                ;;
            *)
                print_error "Invalid option!"
                ;;
        esac
        
        echo ""
        read -p "Press ENTER to continue..."
    done
}

# Execute
main