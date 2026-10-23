#!/usr/bin/env bash
# Checks the two-rice setup (Hyprland with Lelouch, Mango with its own rice). Run it and paste the output:
#   bash ~/nixos-config/scripts/verify.sh; bash ~/nixos-config/scripts/verify-sessions.sh
set -u

repo="$HOME/nixos-config"
pass=0
fail=0

check() {
  local what="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    printf '  ok       %s\n' "$what"
    pass=$((pass + 1))
  else
    printf '  PROBLEM  %s\n' "$what"
    fail=$((fail + 1))
  fi
}

section() { printf '\n== %s\n' "$1"; }

section "Files"
for f in modules/nixos/mango.nix modules/nixos/sessions.nix home/sessions.nix home/rices/mango/default.nix \
         home/rices/mango/README.md home/rices/lelouch/shell/SessionSwitcher.qml; do
  check "$f" test -f "$repo/$f"
done
check "old unused session-switcher.nix removed" test ! -e "$repo/modules/nixos/session-switcher.nix"
check "snapshot tag lelouch-rice exists" git -C "$repo" rev-parse -q --verify refs/tags/lelouch-rice

section "Wiring"
check "flake has the mango input"                  grep -q 'mangowm/mango' "$repo/flake.nix"
check "flake adds the mango NixOS module"          grep -q 'nixosModules.mango' "$repo/flake.nix"
check "flake passes inputs to Home Manager"        grep -q 'extraSpecialArgs' "$repo/flake.nix"
check "host imports mango.nix and sessions.nix"    sh -c "grep -q 'modules/nixos/mango.nix' '$repo/hosts/nixos/default.nix' && grep -q 'modules/nixos/sessions.nix' '$repo/hosts/nixos/default.nix'"
check "home imports both rices"                    sh -c "grep -q 'rices/lelouch' '$repo/home/default.nix' && grep -q 'rices/mango' '$repo/home/default.nix'"
check "home imports sessions.nix"                  grep -q 'sessions.nix' "$repo/home/default.nix"
check "the Lelouch shell still starts under Hyprland only" grep -q 'hyprland-session.target' "$repo/home/rices/lelouch/quickshell.nix"
check "lock screen switcher calls switch-session"  grep -q 'switch-session' "$repo/home/rices/lelouch/shell/SessionSwitcher.qml"

section "After the rebuild"
for s in hyprland mango lelouch; do
  check "session $s is installed" test -f "/run/current-system/sw/share/wayland-sessions/$s.desktop"
done
check "mango"             command -v mango
check "mmsg"              command -v mmsg
check "switch-session"    command -v switch-session
check "relock-if-flagged" command -v relock-if-flagged
check "auto-login starts the wrapper session" sh -c "grep -rqs 'Session=lelouch' /etc/sddm.conf /etc/sddm.conf.d"
check "SDDM logs back in after a logout"      sh -c "grep -rqs 'Relogin=true' /etc/sddm.conf /etc/sddm.conf.d"
check "Mango config written"   test -s "$HOME/.config/mango/config.conf"
check "Mango autostart written" test -s "$HOME/.config/mango/autostart.sh"

section "State"
printf '  this session:     %s\n' "${XDG_SESSION_DESKTOP:-unknown} / ${XDG_CURRENT_DESKTOP:-unknown}"
printf '  chosen for next:  %s\n' "$(cat "$HOME/.config/lelouch/session" 2> /dev/null || echo none yet)"
printf '  relock pending:   %s\n' "$( [ -e "$HOME/.cache/lelouch/relock" ] && echo yes || echo no )"
printf '  installed sessions: %s\n' "$(ls /run/current-system/sw/share/wayland-sessions 2> /dev/null | tr '\n' ' ')"
printf '\n  first lines of ~/.config/mango/config.conf:\n'
head -n 6 "$HOME/.config/mango/config.conf" 2> /dev/null | sed 's/^/    /'

printf '\n%d ok, %d problems\n' "$pass" "$fail"
