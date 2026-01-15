#!/usr/bin/env bash

# Main NixOS Installation Orchestrator
# Coordinates the modular installation process
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"

# Module paths
DISK_MODULE="${MODULES_DIR}/disk.sh"
CONFIG_MODULE="${MODULES_DIR}/config.sh"
NIXOS_MODULE="${MODULES_DIR}/nixos.sh"

# Check if modules exist
check_modules() {
    local missing_modules=()

    for module in "$DISK_MODULE" "$CONFIG_MODULE" "$NIXOS_MODULE"; do
        if [ ! -f "$module" ]; then
            missing_modules+=("$module")
        fi
    done

    if [ ${#missing_modules[@]} -gt 0 ]; then
        log_error "Missing modules:"
        for module in "${missing_modules[@]}"; do
            echo "  - $module"
        done
        exit 1
    fi

    log_success "All modules found"
}

# Show welcome banner
show_welcome() {
    echo -e "${CYAN}"
    cat << 'EOF'
 _______  .__
 \      \ |__|__  _______  ______
 /   |   \|  \  \/  /  _ \/  ___/
/    |    \  |>    <  <_> )___ \
\____|__  /__/__/\_ \____/____  >
        \/         \/         \/

EOF
    echo -e "${NC}NixOS Installation Orchestrator${NC}"
    echo
}

# Run specific module
run_module() {
    local module="$1"
    local command="${2:-}"

    log_info "Running module: $(basename "$module")"

    if [ -n "$command" ]; then
        bash "$module" "$command"
    else
        bash "$module"
    fi
}

# Full installation workflow
full_install() {
    log_header "Full NixOS Installation"
    echo

    # Run each module in sequence
    log_info "Phase 1: Disk Setup"
    run_module "$DISK_MODULE" "setup"
    echo

    log_info "Phase 2: Configuration"
    run_module "$CONFIG_MODULE" "setup"
    echo

    log_info "Phase 3: NixOS Installation"
    run_module "$NIXOS_MODULE" "install"

    echo
    log_success "Full installation complete!"
}

# Disk setup only
disk_setup() {
    log_header "Disk Setup Only"
    run_module "$DISK_MODULE" "setup"
}

# Mount existing filesystems
mount_only() {
    log_header "Mount Existing Filesystems"
    run_module "$DISK_MODULE" "mount"
}

# Configuration only
config_setup() {
    log_header "Configuration Setup"
    run_module "$CONFIG_MODULE" "setup"
}

# NixOS installation only
nixos_install() {
    log_header "NixOS Installation"
    run_module "$NIXOS_MODULE" "install"
}

# Quick install (no confirmations)
quick_install() {
    log_header "Quick Installation (No Confirmation)"
    echo

    log_info "Phase 1: Disk Setup"
    run_module "$DISK_MODULE" "setup"
    echo

    log_info "Phase 2: Configuration"
    run_module "$CONFIG_MODULE" "setup"
    echo

    log_info "Phase 3: NixOS Installation"
    run_module "$NIXOS_MODULE" "quick"

    echo
    log_success "Quick installation complete!"
}

# Show system status
show_status() {
    log_header "System Status"
    echo

    echo "Mount points:"
    mount | grep /mnt | while read line; do
        echo "  $line"
    done

    echo
    echo "Configuration files:"
    if [ -d "/mnt/etc/nixos" ]; then
        ls -la /mnt/etc/nixos/
    else
        echo "  No mounted configuration found"
    fi

    echo
    echo "Available devices:"
    lsblk -d -o NAME,SIZE,MODEL
}

# Show help
show_help() {
    cat << EOF
NixOS Installation Orchestrator

USAGE:
    $0 [COMMAND]

COMMANDS:
    full         - Complete installation (disk + config + nixos)
    disk         - Disk setup and partitioning only
    mount        - Mount existing filesystems only
    config       - Configuration setup only
    nixos        - NixOS installation only
    quick        - Quick installation (no confirmations)
    status       - Show current system status
    help         - Show this help

PHASES:
    1. Disk setup - Partition and mount filesystems
    2. Config setup - Generate and copy configuration files
    3. NixOS install - Install the NixOS system

EXAMPLES:
    $0 full              # Complete installation with confirmations
    $0 disk              # Set up disks only
    $0 config            # Configure only (requires mounted disks)
    $0 nixos             # Install only (requires configuration)
    $0 quick             # Install without any confirmations

For module-specific help:
    $MODULES_DIR/disk.sh help
    $MODULES_DIR/config.sh help
    $MODULES_DIR/nixos.sh help
EOF
}

# Main execution
main() {
    # Check if we're in a NixOS live environment
    if [ ! -f /etc/nixos/configuration.nix ]; then
        log_warning "Not running in NixOS live environment"
        log_warning "This script is designed for NixOS installation from live USB"
        echo
    fi

    # Check modules exist
    check_modules

    case "${1:-full}" in
        full)
            show_welcome
            full_install
            ;;
        disk)
            disk_setup
            ;;
        mount)
            mount_only
            ;;
        config)
            config_setup
            ;;
        nixos)
            nixos_install
            ;;
        quick)
            show_welcome
            quick_install
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
