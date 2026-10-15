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
section() { printf '\n== %s\n' "$1"; }

section "Shell files"
for f in shell Theme Ui TextStore CardFrame Chamfer Glyph Panel DropPanel Popups Scratchpad Bar BarButton \
         CommandCenter SystemPage ControlsPage ConnectPage MediaPage AgendaPage AlertsPage FocusPage \
         Whiteboard DurationField FocusItem Focus Notes Board Tasks History Agenda Lock LockScene Fmt; do
  check "$f.qml" test -f "$shell/$f.qml"
done

section "Files that should be gone"
for f in CenterButton NotesPage Veil Doors Icon Pill Clock Feather; do
  check "$f.qml removed" test ! -e "$shell/$f.qml"
done

section "Edits"
check "volume panel opens through Ui"        contains Status.qml 'Ui.toggleVolume()'
check "media bar item opens the media popup" contains NowPlaying.qml 'Ui.togglePopup("media")'
check "calendar refresh follows its popup"   contains Agenda.qml 'popup === "calendar"'
check "timer icon exists"                    contains Glyph.qml 'kind === "timer"'
check "pencil icon exists"                   contains Glyph.qml 'kind === "pencil"'
check "bell icon exists"                     contains Glyph.qml 'kind === "bell"'
check "lock screen has the exit screenshot"  contains LockScene.qml 'id: shot'
check "lock state has shotReady"             contains LockState.qml 'shotReady'
check "Super+N and Super+T are bound"        grep -q 'ipc call notes toggle' "$repo/home/rices/lelouch/quickshell.nix"

section "Tools"
for t in qs hyprctl grim wpctl pactl paplay nmcli brightnessctl powerprofilesctl cava curl notify-send \
         lock-screen lelouch-lockshot lelouch-chime lelouch-capture lelouch-agenda lelouch-sysinfo recolor wallpaper; do
  check "$t" command -v "$t"
done

section "System"
check "lock screen PAM service" test -f /etc/pam.d/lelouch-lock
check "quickshell service running" systemctl --user is-active --quiet quickshell
check "Syncthing running" systemctl is-active --quiet syncthing

section "Data folders"
for d in "$HOME/Sync/todo" "$HOME/Sync/notes" "$HOME/.config/lelouch" "$HOME/.local/state/lelouch"; do
  check "${d/#$HOME/~}" test -d "$d"
done
check "calendar link saved" test -r "$HOME/.config/lelouch/calendar-url"

section "Lock screen screenshot"
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

section "Recent shell errors (newest last)"
journalctl --user -u quickshell -b -n 300 --no-pager 2> /dev/null | grep -E '\.qml|ERROR|WARN' | tail -n 12 || true

section "Repo"
printf '  uncommitted files: %s\n' "$(git -C "$repo" status --short | wc -l)"
printf '  last commit:       %s\n' "$(git -C "$repo" log -1 --format='%h %s')"

printf '\n%d ok, %d problems\n' "$pass" "$fail"
