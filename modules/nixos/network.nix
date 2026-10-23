{ ... }:

# Wi-Fi first: low ping and no latency spikes.
{
  # Never let the Wi-Fi card doze between packets (the main cause of laggy Wi-Fi ping)
  networking.networkmanager.wifi.powersave = false;

  # The right channels and power limits for the country (change EG if you move)
  hardware.wirelessRegulatoryDatabase = true;

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=EG
    # Intel Wi-Fi: constant awake mode (lower latency, slightly more battery use)
    options iwlmvm power_scheme=1
    options iwlwifi power_save=0
  '';

  # Congestion control and buffering that suit Wi-Fi; mostly helps uploads and calls
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_notsent_lowat" = 131072;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 131072 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };

  # Cached DNS (your router's DNS still comes first; these are only fallbacks)
  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
  };
  networking.networkmanager.dns = "systemd-resolved";
}
