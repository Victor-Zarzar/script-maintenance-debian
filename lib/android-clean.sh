#!/bin/bash

# ============================================
# Android Studio & Emulator Functions
# ============================================

clean_android_studio() {
    print_section "Cleaning Android Studio & Emulator"

    local total_size=0
    local items_cleaned=0

    # AVD cache cleaning
    if [ -d "$HOME/.android/avd" ]; then
        for avd_dir in "$HOME/.android/avd"/*.avd; do
            if [ -d "$avd_dir/cache" ]; then
                local size=$(get_folder_size "$avd_dir/cache")
                if [ "$size" -gt 0 ]; then
                    rm -rf "$avd_dir/cache"/* 2>/dev/null && \
                        print_success "AVD cache ($(basename "$avd_dir")): $(format_bytes $((size * 1024)))"
                    total_size=$((total_size + size))
                    items_cleaned=$((items_cleaned + 1))
                fi
            fi
        done
    fi

    # Android cache directories
    local cache_dirs=(
        "$HOME/.android/cache"
        "$HOME/.android/build-cache"
    )

    for path in "${cache_dirs[@]}"; do
        if [ -d "$path" ]; then
            local size=$(get_folder_size "$path")
            if [ "$size" -gt 0 ]; then
                rm -rf "$path"/* 2>/dev/null && \
                    print_success "$(basename "$path"): $(format_bytes $((size * 1024)))"
                total_size=$((total_size + size))
                items_cleaned=$((items_cleaned + 1))
            fi
        fi
    done

    # Android Studio cache directories
    local studio_cache_dirs=(
        "$HOME/.cache/Google/AndroidStudio"*
        "$HOME/.local/share/Google/AndroidStudio"*/caches
    )

    for pattern in "${studio_cache_dirs[@]}"; do
        for path in $pattern; do
            if [ -d "$path" ]; then
                local size=$(get_folder_size "$path")
                if [ "$size" -gt 0 ]; then
                    rm -rf "$path"/* 2>/dev/null && \
                        print_success "Android Studio cache: $(format_bytes $((size * 1024)))"
                    total_size=$((total_size + size))
                    items_cleaned=$((items_cleaned + 1))
                fi
            fi
        done
    done

    # Android Studio logs
    local log_paths=(
        "$HOME/.local/share/Google/AndroidStudio"*/log
        "$HOME/.cache/Google/AndroidStudio"*/log
    )

    for pattern in "${log_paths[@]}"; do
        for log_path in $pattern; do
            if [ -d "$log_path" ]; then
                local size=$(get_folder_size "$log_path")
                if [ "$size" -gt 0 ]; then
                    rm -rf "$log_path"/* 2>/dev/null && \
                        print_success "Android Studio logs: $(format_bytes $((size * 1024)))"
                    total_size=$((total_size + size))
                    items_cleaned=$((items_cleaned + 1))
                fi
            fi
        done
    done

    # Clean old backups
    if [ -d "$HOME/.config/Google" ]; then
        find "$HOME/.config/Google" -type f -name "*.backup" -mtime +30 2>/dev/null | while read backup; do
            rm -f "$backup" 2>/dev/null
        done
    fi

    # Gradle cache info (not cleaned automatically)
    if [ -d "$HOME/.gradle/caches" ]; then
        local size=$(get_folder_size "$HOME/.gradle/caches")
        if [ "$size" -gt 0 ]; then
            print_info "Gradle cache found: $(format_bytes $((size * 1024)))"
            print_warning "Run './gradlew cleanBuildCache' in your projects to clean safely"
        fi
    fi

    if [ "$items_cleaned" -eq 0 ]; then
        print_info "No Android Studio/Emulator cache found"
    else
        print_success "Total Android cleaned: $(format_bytes $((total_size * 1024)))"
        TOTAL_CLEANED=$((TOTAL_CLEANED + total_size))
    fi

    log_action "Android Studio & Emulator cleaned"
}
