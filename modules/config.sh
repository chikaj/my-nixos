#!/usr/bin/env bash

# Config module - handles user prompts and template processing
# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Prompt for user information
prompt_user_info() {
    log_info "=== User Configuration ==="

    # Hardware profile selection
    select_hardware_profile

    read -p "Enter desired hostname: " HOSTNAME
    if ! validate_hostname "$HOSTNAME"; then
        exit 1
    fi

    read -p "Enter desired time zone (e.g., America/Chicago): " TIMEZONE
    if ! validate_timezone "$TIMEZONE"; then
        exit 1
    fi

    read -p "Enter desired username: " USERNAME
    if ! validate_username "$USERNAME"; then
        exit 1
    fi

    prompt_password "Enter password: " PASSWORD PASSWORD2

    log_info "User configuration complete"
}

# Process NixOS configuration template
process_config_template() {
    local base_template="${SCRIPT_DIR}/../templates/configuration.nix"
    local hardware_dir="${SCRIPT_DIR}/../templates/hardware-specific"
    local output_path="./configuration.nix"

    log_info "Processing NixOS configuration template..."

    # Select appropriate configuration based on hardware profile
    local template_path="$base_template"
    if [ "${FORCE_NVIDIA:-false}" = true ]; then
        template_path="${hardware_dir}/nvidia.nix"
        log_info "Using NVIDIA-specific configuration"
    elif [ "${FORCE_NO_NVIDIA:-false}" = true ]; then
        template_path="${hardware_dir}/no-nvidia.nix"
        log_info "Using non-NVIDIA configuration"
    fi

    if [ ! -f "$base_template" ]; then
        log_error "Configuration template not found at $base_template"
        exit 1
    fi

    # Substitute variables into config template
    sed -e "s|HOSTNAME|$HOSTNAME|g" \
        -e "s|TIMEZONE|$TIMEZONE|g" \
        -e "s|USERNAME|$USERNAME|g" \
        -e "s|PASSWORD|$PASSWORD|g" \
        "$base_template" > "$output_path"

    # Append hardware-specific configuration if needed
    if [ "${FORCE_NVIDIA:-false}" = true ]; then
        log_info "Appending NVIDIA-specific configuration..."
        cat "${hardware_dir}/nvidia.nix" >> "$output_path"
    elif [ "${FORCE_NO_NVIDIA:-false}" = true ]; then
        log_info "Appending non-NVIDIA configuration..."
        cat "${hardware_dir}/no-nvidia.nix" >> "$output_path"
    else
        # Apply auto-detected NVIDIA configuration
        detect_and_configure_nvidia
    fi

    log_success "NixOS configuration created: $output_path"
}

# Process flake template
process_flake_template() {
    local template_path="${SCRIPT_DIR}/../templates/flake.nix"
    local output_path="./flake.nix"

    log_info "Processing flake template..."

    # Substitute variables into flake template
    sed -e "s|HOSTNAME|$HOSTNAME|g" \
    -e "s|USERNAME|$USERNAME|g" \
    "$base_template" > "$output_path"

    log_success "Flake configuration created: $output_path"
}

# Process home-manager template
process_home_template() {
    local base_template="${SCRIPT_DIR}/../templates/home.nix"
    local home_file="/home/${USERNAME}/.config/home-manager/home.nix"

    log_info "Processing home-manager template..."

    if [ ! -f "$template_path" ]; then
        log_error "Home template not found at $template_path"
        exit 1
    fi

    # Create directory and substitute variables
    mkdir -p "$(dirname "$home_file")"
    sed "s|USERNAME|$USERNAME|g" "$base_template" > "$home_file"
    chown "${USERNAME}:${USERNAME}" "$home_file"

    log_success "Home configuration created: $home_file"
}

# Detect and add NVIDIA configuration if needed
detect_and_configure_nvidia() {
    log_info "Configuring hardware settings..."

    local use_nvidia=false

    # Check for forced hardware profiles
    if [ "${FORCE_NVIDIA:-false}" = true ]; then
        use_nvidia=true
        log_info "Using forced NVIDIA configuration"
    elif [ "${FORCE_NO_NVIDIA:-false}" = true ]; then
        use_nvidia=false
        log_info "Using forced non-NVIDIA configuration"
    elif [ "${FORCE_GENERIC:-false}" = true ]; then
        use_nvidia=false
        log_info "Using generic configuration"
    else
        # Auto-detection logic
        local auto_detected=false
        if detect_nvidia; then
            auto_detected=true
            log_info "NVIDIA hardware detected automatically"
        else
            log_info "No NVIDIA hardware detected"
        fi

        # Interactive override option
        if [ "$auto_detected" = true ]; then
            echo
            read -p "Include NVIDIA configuration? (Y/n): " include_nvidia
            case "$include_nvidia" in
                [Nn]|[Nn][Oo])
                    use_nvidia=false
                    log_info "Skipping NVIDIA configuration per user choice"
                    ;;
                *)
                    use_nvidia=true
                    ;;
            esac
        else
            echo
            read -p "Force NVIDIA configuration? (y/N): " force_nvidia
            case "$force_nvidia" in
                [Yy]|[Yy][Ee])
                    use_nvidia=true
                    log_info "Forcing NVIDIA configuration per user choice"
                    ;;
            esac
        fi

        use_nvidia=$auto_detected
    fi

    # Add NVIDIA configuration if needed
    if [ "$use_nvidia" = true ]; then
        log_info "Adding NVIDIA configuration..."

        local nvidia_block='
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    cudaSupport = true;
    # For specific requirements, add deviceSections or busId options here
  };
  services.xserver.videoDrivers = [ "nvidia" ];'

        # Insert NVIDIA block into configuration
        sed -i "/^}/i ${nvidia_block}" ./configuration.nix

        log_success "NVIDIA configuration added"
    else
        log_info "NVIDIA configuration skipped"
    fi
}

# Hardware-specific configuration selection
select_hardware_profile() {
    log_info "Hardware profile selection"
    echo "Available hardware profiles:"
    echo "1. Auto-detect (recommended)"
    echo "2. NVIDIA GPU"
    echo "3. Non-NVIDIA GPU (Intel/AMD)"
    echo "4. Generic/Minimal"

    while true; do
        read -p "Select hardware profile (1-4): " choice
        case "$choice" in
            1)
                log_info "Using auto-detection..."
                return 0
                ;;
            2)
                log_info "Using NVIDIA configuration..."
                export FORCE_NVIDIA=true
                return 0
                ;;
            3)
                log_info "Using non-NVIDIA configuration..."
                export FORCE_NO_NVIDIA=true
                return 0
                ;;
            4)
                log_info "Using generic configuration..."
                export FORCE_GENERIC=true
                return 0
                ;;
            *)
                log_error "Invalid selection. Please choose 1-4."
                ;;
        esac
    done
}

# Copy session files
copy_session_files() {
    local sessions_dir="${SCRIPT_DIR}/../templates/wayland-sessions"
    local target_dir="/mnt/etc/nixos/wayland-sessions"

    if [ -d "$sessions_dir" ]; then
        log_info "Copying wayland session files..."
        mkdir -p "$target_dir"
        cp "$sessions_dir"/*.desktop "$target_dir/" 2>/dev/null || true
        log_success "Session files copied"
    fi
}

# Copy configuration files to mount point
copy_configs_to_system() {
    log_info "Copying configuration files to system..."

    # Ensure target directories exist
    sudo mkdir -p /mnt/etc/nixos

    # Copy main config files
    sudo cp ./configuration.nix /mnt/etc/nixos/
    sudo cp ./flake.nix /mnt/etc/nixos/

    # Copy session files
    copy_session_files

    log_success "Configuration files copied to /mnt/etc/nixos/"
}

# Verify template processing
verify_templates() {
    log_info "Verifying template processing..."

    local errors=0

    # Check for unsubstituted placeholders
    if grep -q "HOSTNAME\|TIMEZONE\|USERNAME\|PASSWORD" /mnt/etc/nixos/configuration.nix; then
        log_error "Found unsubstituted placeholders in configuration.nix"
        errors=$((errors + 1))
    fi

    if grep -q "HOSTNAME\|USERNAME" /mnt/etc/nixos/flake.nix; then
        log_error "Found unsubstituted placeholders in flake.nix"
        errors=$((errors + 1))
    fi

    if [ $errors -eq 0 ]; then
        log_success "Template verification passed"
    else
        log_error "Template verification failed with $errors errors"
        exit 1
    fi
}

# Show final verification steps
show_verification_steps() {
    log_info "=== Verification Steps ==="
    echo
    echo "All configs are now in /mnt/etc/nixos/."
    echo
    echo "Verify:"
    echo "  - Partitions:          lsblk"
    echo "  - Hardware config:       ls -la /mnt/etc/nixos/hardware-configuration.nix"
    echo "  - Mount points:         mount | grep /mnt"
    echo "  - No placeholders:      grep HOSTNAME /mnt/etc/nixos/configuration.nix (should return nothing)"
    echo
    echo "When verified, run:"
    echo "  nixos-install --flake /mnt/etc/nixos#${HOSTNAME}"
    echo
}

# Generate hardware configuration
generate_hardware_config() {
    log_info "Generating hardware configuration..."
    # nixos-generate-config --root /mnt
    # sudo nixos-enter --root /mnt -c 'nixos-generate-config'
    sudo `which nixos-generate-config` --root /mnt
    log_success "Hardware configuration generated"
}

# Main configuration function
setup_config() {
    log_info "Starting configuration setup..."

    # Check if partitions are mounted
    check_partitions_mounted || exit 1



    prompt_user_info
    generate_hardware_config
    process_config_template
    process_flake_template
    process_home_template
    detect_and_configure_nvidia
    copy_configs_to_system
    verify_templates
    show_verification_steps

    log_success "Configuration setup complete"
}

# Show help
show_help() {
    echo "Config module - Handle user configuration and template processing"
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  setup    - Full configuration setup"
    echo "  help     - Show this help"
    echo
}

# Main execution
case "${1:-setup}" in
    setup)
        setup_config
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
