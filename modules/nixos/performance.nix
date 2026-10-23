{ lib, pkgs, ... }:

# Speed and smoothness, tuned for a ThinkPad E14 (Intel graphics, 7.4 GB of RAM).
# Nothing here lowers security or pushes the hardware past what it is built for.
let
  # Power profile while plugged in ("performance" or "balanced"); on battery it is always "balanced"
  acProfile = "performance";
in
{
  # ---- Kernel: Zen (tuned for desktops) ----
  # Alternatives: linuxPackages_xanmod_latest (BBRv3), linuxPackages_latest (plain mainline), linuxPackages (LTS).
  # The scheduler below needs 6.12 or newer. If the first rebuild starts compiling a kernel, press Ctrl+C and tell me.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;

  # ---- Scheduler: LAVD (sched_ext), built for smooth desktops and games; --autopower follows the power profile ----
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--autopower" ];
  };

  # ---- Memory: compressed swap in RAM first, the disk swap only after it ----
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 75;
    priority = 100;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 150;                # zram is fast: swap eagerly
    "vm.page-cluster" = 0;                # no read-ahead from zram
    "vm.vfs_cache_pressure" = 50;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.dirty_background_ratio" = 5;      # smoother writes (USB copies, builds)
    "vm.dirty_ratio" = 15;
  };

  # Out of memory: end the worst offender early instead of freezing the desktop
  systemd.oomd.enable = false;
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 4;
    freeSwapThreshold = 10;
  };

  # ---- CPU and power: power-profiles-daemon stays in charge; plugged in = acProfile, battery = balanced ----
  services.thermald.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemd-run --no-block ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set ${acProfile}"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemd-run --no-block ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
  '';

  # Fewer needless wakeups
  boot.kernelParams = [ "nowatchdog" ];
  boot.blacklistedKernelModules = [ "iTCO_wdt" ];

  # ---- Graphics: hardware video decoding on the Intel iGPU ----
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # ---- Firmware, SSD, boot ----
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  services.fwupd.enable = true;
  services.fstrim.enable = true;
  fileSystems."/".options = [ "noatime" ];
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  # ---- Games: run one with `gamemoderun <game>` (Steam: set the launch option to `gamemoderun %command%`) ----
  programs.gamemode.enable = true;

  # ---- Nix itself: faster downloads and builds ----
  nix.settings = {
    auto-optimise-store = true;
    max-jobs = "auto";
    http-connections = 50;
    connect-timeout = 5;
    download-buffer-size = 268435456;
  };

  # Tools the check script uses
  environment.systemPackages = with pkgs; [ iw pciutils libva-utils lm_sensors ];
}
