#!/bin/bash

# ============================================
# System Cleanup Functions
# ============================================

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
