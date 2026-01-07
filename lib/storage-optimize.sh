#!/bin/bash

# ============================================
# Storage Optimization Functions
# ============================================

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

optimize_databases() {
    print_section "Optimizing System Databases"

    print_info "Updating man database..."
    sudo mandb &>/dev/null

    print_info "Updating locate database..."
    sudo updatedb &>/dev/null

    print_success "Databases optimized"
    log_action "Databases optimized"
}
