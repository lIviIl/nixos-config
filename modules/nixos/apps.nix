{ ... }:

{
  # Apps that need system-level setup (a firewall port, a service, special permissions).
  # Plain apps belong in home/packages.nix instead.

  # LocalSend: installs the app and opens TCP and UDP port 53317
  programs.localsend.enable = true;

  # Cloudflare WARP: enables the background routing daemon and opens UDP port 2408
  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = true;
}
