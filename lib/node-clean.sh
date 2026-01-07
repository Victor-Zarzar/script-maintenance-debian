#!/bin/bash

# ============================================
# Node.js Package Manager Functions
# ============================================

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

clean_bun() {
    print_section "Cleaning Bun Cache"

    if ! command -v bun &> /dev/null; then
        print_info "Bun not installed"
        return
    fi

    local paths=(
        "$HOME/.bun/install/cache"
        "$HOME/.bun/install/global/cache"
    )

    local total_size=0

    for path in "${paths[@]}"; do
        if [ -d "$path" ]; then
            local size=$(get_folder_size "$path")
            if [ "$size" -gt 0 ]; then
                rm -rf "$path"/* 2>/dev/null && \
                    print_success "Cleaned $(basename "$path"): $(format_bytes $((size * 1024)))"
                total_size=$((total_size + size))
            fi
        fi
    done

    # Clean Bun logs
    if [ -d "$HOME/.bun/logs" ]; then
        local size=$(get_folder_size "$HOME/.bun/logs")
        if [ "$size" -gt 0 ]; then
            find "$HOME/.bun/logs" -type f -mtime +7 -delete 2>/dev/null
            print_success "Old logs cleaned: $(format_bytes $((size * 1024)))"
            total_size=$((total_size + size))
        fi
    fi

    if [ "$total_size" -gt 0 ]; then
        TOTAL_CLEANED=$((TOTAL_CLEANED + total_size))
        print_success "Total Bun cleaned: $(format_bytes $((total_size * 1024)))"
    else
        print_info "No Bun cache to clean"
    fi

    log_action "Bun cleaned"
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
