# Non-NVIDIA hardware configuration
# Use this template for systems without NVIDIA GPUs
# This provides optimal configuration for Intel, AMD, and integrated graphics

# OpenGL and graphics support
hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
};

# X server configuration for non-NVIDIA systems
services.xserver = {
  # Auto-detect appropriate video drivers
  videoDrivers = [ "modesetting" ];

  # Use libinput for better touchpad/mouse support
  libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      disableWhileTyping = true;
    };
  };
};

# Intel graphics support (if applicable)
hardware.intel-gpu-tools.enable = true;

# AMD graphics support (if applicable)
hardware.amdgpu.opencl = true;
hardware.amdgpu.amdvlk = true;

# Generic kernel parameters for better performance
boot.kernelParams = [
  # Intel GPU optimization
  "i915.fastboot=1"
  "i915.enable_psr=1"

  # AMD GPU optimization
  "amdgpu.dc=1"
  "amdgpu.pcie_gen4=1"

  # General graphics performance
  "quiet"
  "splash"
];

# Power management for laptops
powerManagement = {
  enable = true;
  cpuFreqGovernor = "ondemand";
};

# Backlight control for laptops
programs.light.enable = true;

# Audio configuration
hardware.pulseaudio.enable = false;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = false;
};

# Kernel modules for hardware support
boot.kernelModules = [
  "i915"          # Intel graphics
  "amdgpu"         # AMD graphics
  "nouveau"         # NVIDIA (disabled by default)
  "acpi_call"      # Laptop backlight
  "video"           # Video acceleration
  "kvm"            # Virtualization
];

# Blacklist problematic drivers
boot.blacklistedKernelModules = [
  "nouveau"         # Disable NVIDIA open source driver
  "i2c_nvidia_gpu" # Disable NVIDIA I2C
];

# Hardware-specific environment variables
environment.sessionVariables = {
  # Intel GPU optimizations
  INTEL_DEBUG = "nocache";
  VDPAU_DRIVER = "va_gl";

  # AMD GPU optimizations
  AMD_DEBUG = "nohangcheck";

  # Wayland optimizations
  WLR_RENDERER = "auto";
  WLR_NO_HARDWARE_CURSORS = "1";
};

# Enable hardware video acceleration
nixpkgs.config.packageOverrides = pkgs: {
  vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
};

# Package selection for non-NVIDIA systems
environment.systemPackages = with pkgs; [
  # Graphics and display utilities
  mesa
  mesa.drivers
  libva
  libva-utils
  vulkan-tools
  glxinfo

  # Intel GPU tools
  intel-gpu-tools
  mesa-demos

  # AMD GPU tools
  radeontop
  amdgpu-pro

  # Display management
  arandr
  autorandr

  # Color management
  colord
  gnome-color-manager
];

# Display manager configuration for non-NVIDIA
services.displayManager = {
  # Auto-detect display manager
  autoLogin = {
    enable = false;
  };
};

# Enable Wayland session support
services.xserver = {
  enable = true;
  layout = "us";
  xkbVariant = "";

  # Enable display managers
  displayManager = {
    gdm = {
      enable = true;
      wayland = true;
    };
  };
};

# Power management for laptops (if applicable)
services.thermald.enable = true;
services.tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    START_CHARGE_THRESH_BAT0 = 75;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };
};

# Battery monitoring (laptops)
services.upower = {
  enable = true;
  percentageLow = 20;
  percentageCritical = 5;
};

# Fan control (if supported)
services.fwupd.enable = true;

# Kernel parameters for better hardware compatibility
boot.kernel.sysctl = {
  "vm.swappiness" = 10;
  "vm.vfs_cache_pressure" = 50;
  "fs.inotify.max_user_watches" = 524288;
};

# Hardware-specific services
services = {
  # Hardware sensor monitoring
  lm_sensors = {
    enable = true;
  };

  # Automatic hardware firmware updates
  fwupd = {
    enable = true;
  };
};

# Wayland compositor support
xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
  ];
};
