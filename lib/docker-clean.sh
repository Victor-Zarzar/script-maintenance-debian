#!/bin/bash

# ============================================
# Docker Functions
# ============================================

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
