{ pkgs, ... }:

{
  # Lets root's git trust your repo (needed for sudo nixos-rebuild with flakes)
  programs.git = {
    enable = true;
    config.safe.directory = "/home/Vi/nixos-config";
  };

  environment.systemPackages = [
    # rebuild  (or: rebuild update)
    (pkgs.writeShellApplication {
      name = "rebuild";
      runtimeInputs = [ pkgs.git ];
      text = ''
        cd /home/Vi/nixos-config || exit 1

        if [ "''${1:-}" = "update" ]; then
          nix flake update
        fi

        git add -A
        sudo nixos-rebuild switch --flake .
        git add -A
        git commit -m "rebuild: $(date '+%Y-%m-%d %H:%M')" || echo "Nothing new to commit"
        git push -u origin main
      '';
    })
  ];
}
