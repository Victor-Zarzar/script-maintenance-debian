#!/bin/bash

# ============================================
# System Update Functions
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
