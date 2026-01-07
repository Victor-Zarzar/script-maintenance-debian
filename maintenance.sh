#!/bin/bash

# ============================================
# Advanced Debian/Ubuntu Maintenance Script
# Modular Architecture
# ============================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library modules
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/helpers.sh"
source "$SCRIPT_DIR/lib/system-update.sh"
source "$SCRIPT_DIR/lib/package-clean.sh"
source "$SCRIPT_DIR/lib/node-clean.sh"
source "$SCRIPT_DIR/lib/flutter-clean.sh"
source "$SCRIPT_DIR/lib/android-clean.sh"
source "$SCRIPT_DIR/lib/docker-clean.sh"
source "$SCRIPT_DIR/lib/system-clean.sh"
source "$SCRIPT_DIR/lib/storage-optimize.sh"

# Global variables
TOTAL_CLEANED=0
LOG_FILE="$HOME/debian_maintenance_$(date +%Y%m%d_%H%M%S).log"

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
    echo "9)  Clean Bun"
    echo "10) Clean PNPM"
    echo "11) Clean Flutter/Dart/FVM"
    echo "12) Clean Android Studio"
    echo "13) Clean Docker"
    echo "14) Remove old kernels"
    echo "15) Clean logs"
    echo "16) Clean user caches"
    echo "17) Clean temporary files"
    echo "18) Clean PIP cache"
    echo "19) Optimize databases"
    echo "20) Verify system health"
    echo "21) View action log"
    echo "0)  Exit"
    echo ""
    echo -n "Choose an option: "
}

run_full_maintenance() {
    local initial_space=$(get_disk_usage)

    print_header
    echo -e "${YELLOW}Initial free space: $initial_space${NC}\n"

    # System updates
    update_system
    fix_broken_packages
    remove_orphans
    clean_package_cache

    # Package managers
    clean_snap_packages
    clean_flatpak

    # Development tools
    clean_nvm_npm
    clean_bun
    clean_pnpm
    clean_flutter_dart
    clean_android_studio

    # System maintenance
    clean_docker
    clean_old_kernels
    clean_logs
    clean_user_caches
    clean_system_temp
    clean_pip_cache

    # Optimization
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
    if [ ! -f /etc/debian_version ]; then
        print_error "This script is for Debian/Ubuntu systems only!"
        exit 1
    fi

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
            9) clean_bun ;;
            10) clean_pnpm ;;
            11) clean_flutter_dart ;;
            12) clean_android_studio ;;
            13) clean_docker ;;
            14) clean_old_kernels ;;
            15) clean_logs ;;
            16) clean_user_caches ;;
            17) clean_system_temp ;;
            18) clean_pip_cache ;;
            19) optimize_databases ;;
            20) verify_system_health ;;
            21) cat "$LOG_FILE" | less ;;
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

main
