#!/bin/bash

# ============================================
# Package Management Functions
# ============================================

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
