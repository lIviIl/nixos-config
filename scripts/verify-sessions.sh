#!/usr/bin/env bash
# Checks the two-rice setup (Hyprland with Lelouch, Mango with its own rice), including a dry run of the login
# session so a broken one is caught BEFORE a reboot. Run it and paste the output:
#   bash ~/nixos-config/scripts/verify-sessions.sh
set -u

repo="$HOME/nixos-config"
dir=/etc/lelouch/wayland-sessions
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
check "snapshot tag lelouch-rice exists" git -C "$repo" rev-parse -q --verify refs/tags/lelouch-rice

section "Wiring"
check "flake has the mango input"                  grep -q 'mangowm/mango' "$repo/flake.nix"
check "host imports mango.nix and sessions.nix"    sh -c "grep -q 'modules/nixos/mango.nix' '$repo/hosts/nixos/default.nix' && grep -q 'modules/nixos/sessions.nix' '$repo/hosts/nixos/default.nix'"
check "home imports both rices and sessions.nix"   sh -c "grep -q 'rices/lelouch' '$repo/home/default.nix' && grep -q 'rices/mango' '$repo/home/default.nix' && grep -q 'sessions.nix' '$repo/home/default.nix'"
check "the Lelouch shell still starts under Hyprland only" grep -q 'hyprland-session.target' "$repo/home/rices/lelouch/quickshell.nix"
check "lock screen switcher uses the stable folder" grep -q '/etc/lelouch/wayland-sessions' "$repo/home/rices/lelouch/shell/SessionSwitcher.qml"

section "The way back from Mango"
check "login session resets a failing choice"      grep -q "printf 'hyprland" "$repo/modules/nixos/sessions.nix"
check "switch-session restarts into the chosen desktop" grep -q "systemctl reboot" "$repo/home/sessions.nix"
check "Mango key: Super+Shift+E goes back"         grep -q 'SUPER+SHIFT,e,spawn,switch-session hyprland' "$repo/home/rices/mango/default.nix"
check "Mango key: Super+Ctrl+H goes back"          grep -q 'SUPER+CTRL,h,spawn,switch-session hyprland' "$repo/home/rices/mango/default.nix"
check "Mango first-start hint"                     grep -q 'mango-hint-seen' "$repo/home/rices/mango/default.nix"
check "launcher entry: switch to Hyprland"         test -f "/etc/profiles/per-user/$USER/share/applications/switch-to-hyprland.desktop"
check "launcher entry: switch to Mango"            test -f "/etc/profiles/per-user/$USER/share/applications/switch-to-mango.desktop"

section "After the rebuild"
check "the desktop list exists at $dir" test -d "$dir"
for s in hyprland mango lelouch; do
  check "session $s is listed" test -f "$dir/$s.desktop"
done
for c in mango mmsg switch-session relock-if-flagged fuzzel kitty; do
  check "$c" command -v "$c"
done
check "auto-login started the wrapper session this boot" sh -c "journalctl -b -u display-manager --no-pager 2> /dev/null | grep -q lelouch.desktop"
check "Mango config written"    test -s "$HOME/.config/mango/config.conf"
check "Mango autostart written" test -s "$HOME/.config/mango/autostart.sh"
check "Mango config contains the way back" grep -q 'switch-session hyprland' "$HOME/.config/mango/config.conf"

section "Login session dry run (what the next login would start; nothing is launched)"
wrapper="$(sed -n 's/^Exec=//p' "$dir/lelouch.desktop" 2> /dev/null | head -n 1)"
if [ -n "$wrapper" ] && [ -x "$wrapper" ]; then
  for choice in none hyprland mango; do
    tmp="$(mktemp -d)"
    if [ "$choice" != none ]; then
      mkdir -p "$tmp/.config/lelouch"
      printf '%s\n' "$choice" > "$tmp/.config/lelouch/session"
    fi
    result="$(HOME="$tmp" LELOUCH_DRY_RUN=1 "$wrapper" 2>&1 | tr '\n' ' ')"
    rm -rf "$tmp"
    printf '  saved choice %-9s -> %s\n' "$choice" "$result"
    case "$result" in
      *"cmd="?*) pass=$((pass + 1)) ;;
      *)
        printf '  PROBLEM  the login session would start nothing for "%s"\n' "$choice"
        fail=$((fail + 1))
        ;;
    esac
  done
else
  printf '  PROBLEM  could not find the login wrapper (%s)\n' "${wrapper:-no Exec line}"
  fail=$((fail + 1))
fi

section "State"
printf '  this session:       %s / %s\n' "${XDG_SESSION_DESKTOP:-unknown}" "${XDG_CURRENT_DESKTOP:-unknown}"
printf '  chosen for next:    %s\n' "$(cat "$HOME/.config/lelouch/session" 2> /dev/null || echo 'none yet (hyprland)')"
printf '  seamless switching: %s\n' "$( [ -e /etc/lelouch/seamless ] && echo on || echo 'off (the login screen appears after a switch)' )"
printf '  desktops listed:    %s\n' "$(ls "$dir" 2> /dev/null | tr '\n' ' ')"

section "What Mango was given (~/.config/mango/config.conf)"
sed -n '1,45p' "$HOME/.config/mango/config.conf" 2> /dev/null | sed 's/^/  /'
section "Mango autostart (~/.config/mango/autostart.sh)"
sed -n '1,20p' "$HOME/.config/mango/autostart.sh" 2> /dev/null | sed 's/^/  /'

printf '\n%d ok, %d problems\n' "$pass" "$fail"
