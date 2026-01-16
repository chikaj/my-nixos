#!/usr/bin/env bash

# NixOS module - handles system installation
# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"


refresh_flake_lock() {
  # Ensure flake.lock matches THIS environment (the live ISO’s Nix)
  local flake_dir="/mnt/etc/nixos"
  if [ -f "$flake_dir/flake.nix" ]; then
    echo "[INFO] Refreshing flake.lock in $flake_dir for this environment..."
    # Remove possibly stale lock created elsewhere
    sudo rm -f "$flake_dir/flake.lock"
    # Recreate it with the current Nix on the installer
    sudo nix --extra-experimental-features 'nix-command flakes' \
      flake update --recreate-lock-file --flake "$flake_dir"
    echo "[SUCCESS] flake.lock refreshed."
  else
    echo "[WARNING] No flake.nix in $flake_dir; skipping flake lock refresh."
  fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."

    # Check if partitions are mounted
    check_partitions_mounted || exit 1

    # Check if configuration files exist
    if [ ! -f "/mnt/etc/nixos/configuration.nix" ]; then
        log_error "Configuration file not found. Run config module first."
        exit 1
    fi

    if [ ! -f "/mnt/etc/nixos/flake.nix" ]; then
        log_error "Flake file not found. Run config module first."
        exit 1
    fi

    # Check if hardware configuration exists
    if [ ! -f "/mnt/etc/nixos/hardware-configuration.nix" ]; then
        log_error "Hardware configuration not found. Run config module first."
        exit 1
    fi

    log_success "System requirements check passed"
}

# Show installation preview
show_install_preview() {
    log_info "=== Installation Preview ==="
    echo
    echo "Target device: $(lsblk -d -o NAME,SIZE | grep -E '^sd|^nvme' | head -1)"
    echo "Hostname: $(grep "networking.hostName" /mnt/etc/nixos/configuration.nix | cut -d'"' -f2)"
    echo "Timezone: $(grep "time.timeZone" /mnt/etc/nixos/configuration.nix | cut -d'"' -f2)"
    echo "Username: $(grep "users.users\." /mnt/etc/nixos/configuration.nix | grep -v "isNormalUser" | head -1 | cut -d'.' -f2 | cut -d' ' -f1)"
    echo
    echo "Mount points:"
    mount | grep /mnt | while read line; do
        echo "  $line"
    done
    echo
    echo "Configuration files:"
    ls -la /mnt/etc/nixos/
    echo
}

# Run NixOS installation
install_nixos() {
    log_info "Starting NixOS installation..."

    local hostname
    hostname=$(grep "networking.hostName" /mnt/etc/nixos/configuration.nix | cut -d'"' -f2)
    refresh_flake_lock

    # Run the installation
    if sudo nixos-install --flake "/mnt/etc/nixos#${hostname}"; then
        log_success "NixOS installation completed successfully!"
    else
        log_error "NixOS installation failed!"
        exit 1
    fi
}

# Post-installation verification
post_install_verify() {
    log_info "Running post-installation verification..."

    # Check if system was installed
    if [ -d "/mnt/nix/var/nix/profiles/system" ]; then
        log_success "System profiles found"
    else
        log_warning "System profiles not found"
    fi

    # Check bootloader
    if [ -f "/mnt/boot/EFI/BOOT/BOOTX64.EFI" ] || [ -f "/mnt/boot/EFI/nixos" ]; then
        log_success "Bootloader files found"
    else
        log_warning "Bootloader files not found"
    fi

    log_success "Post-installation verification complete"
}

# Show final instructions
show_final_instructions() {
    log_info "=== Installation Complete ==="
    echo
    echo "✅ NixOS has been successfully installed!"
    echo
    echo "Next steps:"
    echo "1. Remove the installation media"
    echo "2. Reboot the system"
    echo "3. Login with your username and password"
    echo
    echo "After first boot:"
    echo "- Update your system: sudo nixos-rebuild switch --update"
    echo "- Explore your configuration in /etc/nixos/"
    echo "- Configure additional users and services as needed"
    echo
    log_success "Installation process complete!"
}

# Install NixOS (main function)
install_system() {
    log_info "Starting NixOS installation process..."

    check_requirements
    show_install_preview

    # Confirm installation
    echo
    read -p "Proceed with installation? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi

    install_nixos
    post_install_verify
    show_final_instructions
}

# Quick install (skip confirmation)
quick_install() {
    log_info "Starting quick NixOS installation..."

    check_requirements
    install_nixos
    post_install_verify
    show_final_instructions
}

# Show help
show_help() {
    echo "NixOS module - Handle system installation"
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  install    - Full NixOS installation with confirmation"
    echo "  quick      - Quick installation without confirmation"
    echo "  verify     - Verify system requirements only"
    echo "  help       - Show this help"
    echo
}

# Main execution
case "${1:-install}" in
    install)
        install_system
        ;;
    quick)
        quick_install
        ;;
    verify)
        check_requirements
        log_success "System requirements verification passed"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
