#!/usr/bin/env bash

# Common utilities and functions for NixOS installation
set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Validation functions
validate_device() {
    local device="$1"
    if [ -z "$device" ]; then
        log_error "Device name is required"
        return 1
    fi
    if [ ! -b "$device" ]; then
        log_error "Device $device does not exist or is not a block device"
        return 1
    fi
    return 0
}

validate_hostname() {
    local hostname="$1"
    if [ -z "$hostname" ]; then
        log_error "Hostname is required"
        return 1
    fi
    # Basic hostname validation
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
        log_error "Invalid hostname format"
        return 1
    fi
    return 0
}

validate_timezone() {
    local timezone="$1"
    if [ -z "$timezone" ]; then
        log_error "Timezone is required"
        return 1
    fi
    return 0
}

validate_username() {
    local username="$1"
    if [ -z "$username" ]; then
        log_error "Username is required"
        return 1
    fi
    # Basic username validation
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "Invalid username format"
        return 1
    fi
    return 0
}

# Secure password input
prompt_password() {
    local prompt="$1"
    local password_var="$2"
    local password_confirm_var="$3"

    while true; do
        read -s -p "$prompt" password
        echo
        read -s -p "Confirm $prompt" password_confirm
        echo

        if [ "$password" = "$password_confirm" ]; then
            eval "$password_var=\$password"
            eval "$password_confirm_var=\$password_confirm"
            break
        else
            log_error "Passwords do not match. Please try again."
        fi
    done
}

# Check if running as root when needed
require_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This operation requires root privileges"
        exit 1
    fi
}

# Check if partitions are mounted
check_partitions_mounted() {
    if ! mount | grep -q "/mnt" ; then
        log_error "Partitions are not mounted. Please run disk setup first."
        return 1
    fi
    return 0
}

# Detect NVIDIA hardware
detect_nvidia() {
    if lspci | grep -qi 'nvidia'; then
        return 0
    else
        return 1
    fi
}

# Source directory detection
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}
