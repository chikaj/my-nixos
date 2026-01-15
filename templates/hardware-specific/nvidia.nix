# NVIDIA-specific hardware configuration
# Use this template for systems with NVIDIA GPUs
# This will be included in the main configuration.nix

# NVIDIA GPU configuration with full support
hardware.nvidia = {
  # Enable modesetting for proper Wayland support
  modesetting.enable = true;

  # Power management (disable if you experience issues)
  powerManagement.enable = false;
  powerManagement.finegrained = false;

  # Enable NVIDIA settings application
  nvidiaSettings = true;

  # Use stable driver package
  package = config.boot.kernelPackages.nvidiaPackages.stable;

  # Enable CUDA support for development/GPU acceleration
  cudaSupport = true;

  # For specific requirements, add device sections or bus ID options
  # Example: deviceSection = ''
  #   Device "nvidia"
  #     Identifier "Device0"
  #     Driver "nvidia"
  #     VendorName "NVIDIA Corporation"
  #     BusID "PCI:1:0:0"
  #   EndDevice
  # '';

  # For multiple GPUs, you can specify prime offloading
  # prime.offload.enable = true;
  # prime.offload.enableOffloadCmd = true;
};

# Configure X server to use NVIDIA driver
services.xserver.videoDrivers = [ "nvidia" ];

# Enable OpenGL for proper GPU rendering
hardware.opengl.enable = true;

# Optional: Enable NVIDIA container toolkit for Docker
# virtualisation.docker.enableNvidia = true;

# Optional: Configure PRIME offloading for hybrid GPU systems
# hardware.nvidia.prime = {
#   offload = {
#     enable = true;
#     enableOffloadCmd = true;
#   };
#   # Intel GPU bus ID (for hybrid systems)
#   intelBusId = "PCI:0:2:0";
#   # NVIDIA GPU bus ID
#   nvidiaBusId = "PCI:1:0:0";
# };

# Optional: Enable Power Management
# Set to true if you want aggressive power saving
# Set to false if you experience performance issues
services.xserver.deviceSection = ''
#   Option "PowerMizerEnable" "true"
#   Option "RegistryDwords" "PowerMizerLevel=0x1"
# '';

# Optional: Enable Wayland compositor optimizations
# environment.sessionVariables = {
#   GBM_BACKEND = "nvidia-drm";
#   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
#   WLR_NO_HARDWARE_CURSORS = "1";
#   LIBVA_DRIVER_NAME = "nvidia";
#   __EGL_VENDOR_LIBRARY_NAME = "nvidia";
# };
