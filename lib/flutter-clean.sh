#!/bin/bash

# ============================================
# Flutter/Dart/FVM Functions
# ============================================

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
