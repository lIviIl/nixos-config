#!/usr/bin/env bash
# Checks that everything the shell needs is in place. Run it and paste the output:
#   bash ~/nixos-config/scripts/verify.sh
set -u

repo="$HOME/nixos-config"
shell="$repo/home/rices/lelouch/shell"
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

contains() { grep -q -- "$2" "$shell/$1"; }
lacks() { ! grep -q -- "$2" "$shell/$1"; }
section() { printf '\n== %s\n' "$1"; }

section "Shell files"
for f in shell Theme Ui TextStore CardFrame Chamfer Glyph Panel DropPanel Popups Scratchpad Bar BarButton BarDivider \
         CommandCenter SystemPage ControlsPage ConnectPage MediaPage AgendaPage AlertsPage FocusPage LayoutPage \
         Whiteboard DurationField FocusItem Focus Tiling Workspaces Notes Board Tasks History Agenda Lock LockScene Fmt Visualizer; do
  check "$f.qml" test -f "$shell/$f.qml"
done
check "workspace pictures folder" test -d "$shell/assets/workspaces"

section "Files that should be gone"
for f in CenterButton NotesPage Veil Doors Icon Pill Clock Feather; do
  check "$f.qml removed" test ! -e "$shell/$f.qml"
done

section "Panels are never unmapped (the bar-click fix)"
check "drop panels have no visible binding"       lacks DropPanel.qml 'visible:'
check "drop panels shrink to a pixel when closed" contains DropPanel.qml 'shown ? cardWidth : 1'
check "command center has no visible binding"     lacks CommandCenter.qml 'visible:'
check "command center shrinks when closed"        contains CommandCenter.qml 'shown ? drawerWidth : 1'
check "non-modal panels stay mapped"              contains Panel.qml 'visible: modal ? shown : true'
check "no click masks anywhere"                   sh -c "! grep -l 'mask: Region' '$shell'/*.qml | grep -v Notifications.qml"
check "Esc closes the notes overlay"              contains Scratchpad.qml 'enabled: pad.open'
check "Esc closes drop panels"                    contains DropPanel.qml 'enabled: win.open'

section "Edits"
check "volume panel opens through Ui"             contains Status.qml 'Ui.toggleVolume()'
check "calendar refresh follows its panel"        contains Agenda.qml 'popup === "calendar"'
check "lock: screenshot is above the red"         contains LockScene.qml 'z: 10'
check "toasts follow Ui.rightInset"               contains Notifications.qml 'Ui.rightInset'
check "bar buttons use a plain mouse area"        lacks BarButton.qml 'TapHandler'
check "layout icons exist"                        contains Glyph.qml 'kind === "tile-scrolling"'
check "layout panel exists"                       contains Popups.qml 'name: "layout"'
check "workspaces read pictures"                  contains Workspaces.qml 'assets/workspaces'
check "Super+N, Super+T and Super+Y are bound"    sh -c "grep -q 'ipc call notes toggle' '$repo/home/rices/lelouch/quickshell.nix' && grep -q 'ipc call tiling cycle' '$repo/home/rices/lelouch/quickshell.nix'"
check "layout is restored from its Lua file"      grep -q 'layout.lua' "$repo/home/rices/lelouch/tiling.nix"
check "tiling.nix is imported"                    grep -q 'tiling.nix' "$repo/home/rices/lelouch/default.nix"
check "Zen has no theming left"                   sh -c "! grep -q -e userChrome -e colors-zen '$repo/home/apps.nix'"
check "Spicetify is the Spotify setup"            grep -q 'programs.spicetify' "$repo/home/apps.nix"

section "IPC targets the shell answers to"
for t in launcher wallpaper center lock calendar media layout alerts focus notes tiling; do
  check "target $t" sh -c "qs -c lelouch ipc show 2>/dev/null | grep -qw '$t'"
done

section "Tools"
for t in qs hyprctl wpctl pactl paplay nmcli brightnessctl powerprofilesctl cava curl notify-send \
         lock-screen lelouch-lockshot lelouch-chime lelouch-capture lelouch-agenda lelouch-sysinfo recolor wallpaper \
         vesktop spotify; do
  check "$t" command -v "$t"
done
check "zen" sh -c 'command -v zen || command -v zen-beta'

section "System"
check "lock screen PAM service" test -f /etc/pam.d/lelouch-lock
check "quickshell service running" systemctl --user is-active --quiet quickshell
check "Syncthing running" systemctl is-active --quiet syncthing
printf '  current tiling layout: %s\n' "$(hyprctl getoption general:layout 2> /dev/null | head -n 1)"
printf '  saved layout file:     %s\n' "$(cat "$HOME/.local/state/lelouch/layout.lua" 2> /dev/null || echo none yet)"

section "Data folders"
for d in "$HOME/Sync/todo" "$HOME/Sync/notes" "$HOME/.config/lelouch" "$HOME/.local/state/lelouch" "$HOME/.config/vesktop/settings"; do
  check "${d/#$HOME/~}" test -d "$d"
done
check "calendar link saved" test -r "$HOME/.config/lelouch/calendar-url"
check "Vesktop QuickCSS written" test -s "$HOME/.config/vesktop/settings/quickCss.css"

section "Lock screen screenshot (any message from grim appears here)"
output="$(hyprctl monitors 2> /dev/null | awk '/^Monitor/ {print $2; exit}')"
if [ -n "$output" ] && command -v lelouch-lockshot > /dev/null; then
  lelouch-lockshot "$output"
  check "screenshot for $output" test -s "$HOME/.cache/lelouch/lockshot-$output.jpg"
  rm -f "$HOME/.cache/lelouch/lockshot-$output.jpg"
else
  printf '  PROBLEM  could not find a monitor or lelouch-lockshot\n'
  fail=$((fail + 1))
fi

section "Calendar"
if [ -r "$HOME/.config/lelouch/calendar-url" ] && command -v lelouch-agenda > /dev/null; then
  result="$(lelouch-agenda "$(date -d '-30 days' +%F)" "$(date -d '+60 days' +%F)" 2>&1)"
  case "$result" in
    \[*)
      printf '  ok       calendar read: %s events in the window\n' "$(printf '%s' "$result" | grep -o '"title"' | wc -l)"
      pass=$((pass + 1))
      ;;
    *)
      printf '  PROBLEM  calendar: %s\n' "$(printf '%s' "$result" | tail -n 1 | cut -c1-160)"
      fail=$((fail + 1))
      ;;
  esac
else
  printf '  skipped  no calendar link saved yet\n'
fi

section "Windows the shell has on screen right now (closed panels show as 1x1)"
hyprctl layers 2> /dev/null | grep -E 'namespace|xywh' | paste - - 2> /dev/null | sed 's/^/  /' | cut -c1-150 || true

section "Recent shell errors (newest last)"
journalctl --user -u quickshell -b -n 300 --no-pager 2> /dev/null | grep -E '\.qml|ERROR|WARN' | tail -n 12 || true

section "Repo"
printf '  uncommitted files: %s\n' "$(git -C "$repo" status --short | wc -l)"
printf '  last commit:       %s\n' "$(git -C "$repo" log -1 --format='%h %s')"

printf '\n%d ok, %d problems\n' "$pass" "$fail"
