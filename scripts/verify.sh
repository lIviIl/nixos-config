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
for f in shell Theme Ui TextStore CardFrame Chamfer Glyph Panel DropPanel Popups Scratchpad Bar BarButton \
         CommandCenter SystemPage ControlsPage ConnectPage MediaPage AgendaPage AlertsPage FocusPage \
         Whiteboard DurationField FocusItem Focus Notes Board Tasks History Agenda Lock LockScene Fmt Visualizer; do
  check "$f.qml" test -f "$shell/$f.qml"
done

section "Files that should be gone"
for f in CenterButton NotesPage Veil Doors Icon Pill Clock Feather; do
  check "$f.qml removed" test ! -e "$shell/$f.qml"
done

section "Edits"
check "volume panel opens through Ui"               contains Status.qml 'Ui.toggleVolume()'
check "calendar refresh follows its panel"          contains Agenda.qml 'popup === "calendar"'
check "lock: screenshot is above the red"           contains LockScene.qml 'z: 10'
check "no click masks on drop panels"               lacks DropPanel.qml 'mask:'
check "no click mask on the command center"         lacks CommandCenter.qml 'mask:'
check "no click mask on panels"                     lacks Panel.qml 'mask:'
check "command center window follows its card"      contains CommandCenter.qml 'implicitHeight: winHeight'
check "command center keyboard focus is constant"   contains CommandCenter.qml 'WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand'
check "drop panel window follows its card"          contains DropPanel.qml 'implicitHeight: winHeight'
check "scratchpad sizes from the screen"            contains Scratchpad.qml 'screen ? screen.width'
check "notes overlay is non-modal"                  contains Scratchpad.qml 'modal: false'
check "notes overlay has its IPC handler"           contains Scratchpad.qml 'target: "notes"'
check "no CLOSE label on drop panels"               lacks DropPanel.qml 'text: "CLOSE"'
check "no phase label on the Focus card"            lacks FocusPage.qml 'subtitle: Focus.phaseLabel'
check "toasts follow Ui.rightInset"                 contains Notifications.qml 'Ui.rightInset'
check "bar buttons use a plain mouse area"          lacks BarButton.qml 'TapHandler'
check "Super+N and Super+T are bound"               grep -q 'ipc call notes toggle' "$repo/home/rices/lelouch/quickshell.nix"
check "Spicetify is the Spotify setup"              grep -q 'programs.spicetify' "$repo/home/apps.nix"
check "Spotifast is gone"                           sh -c "! grep -q spotifast '$repo/home/apps.nix' '$repo/flake.nix'"

section "IPC targets the shell answers to"
for t in launcher wallpaper center lock calendar media alerts focus notes; do
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

section "Data folders"
for d in "$HOME/Sync/todo" "$HOME/Sync/notes" "$HOME/.config/lelouch" "$HOME/.local/state/lelouch" "$HOME/.config/vesktop/settings"; do
  check "${d/#$HOME/~}" test -d "$d"
done
check "calendar link saved" test -r "$HOME/.config/lelouch/calendar-url"

section "Wallpaper colours reach the apps (run: wallpaper, then this again)"
check "Vesktop QuickCSS written"      test -s "$HOME/.config/vesktop/settings/quickCss.css"
check "Zen colours written"           test -s "$HOME/.cache/matugen/colors-zen.css"
check "Zen page colours written"      test -s "$HOME/.cache/matugen/colors-zen-content.css"

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

section "Zen (if it still looks plain, this is what I need)"
printf '  running: %s\n' "$(pgrep -fc 'zen' 2> /dev/null || echo 0)"
printf '  profiles.ini:\n'
sed 's/^/    /' "$HOME/.zen/profiles.ini" 2> /dev/null || printf '    (none)\n'
for p in "$HOME"/.zen/*/; do
  [ -d "$p" ] || continue
  printf '  %s\n' "${p/#$HOME/~}"
  printf '    chrome/userChrome.css: %s\n' "$( [ -f "$p/chrome/userChrome.css" ] && head -n 1 "$p/chrome/userChrome.css" || echo missing )"
  printf '    chrome/userContent.css: %s\n' "$( [ -f "$p/chrome/userContent.css" ] && echo present || echo missing )"
  printf '    stylesheets pref in user.js: %s\n' "$(grep -c 'legacyUserProfileCustomizations' "$p/user.js" 2> /dev/null || echo 0)"
done

section "Windows the shell has on screen right now"
hyprctl layers 2> /dev/null | grep -E 'Monitor|namespace' | sed 's/^/  /' | cut -c1-110 || true

section "Recent shell errors (newest last)"
journalctl --user -u quickshell -b -n 300 --no-pager 2> /dev/null | grep -E '\.qml|ERROR|WARN' | tail -n 12 || true

section "Repo"
printf '  uncommitted files: %s\n' "$(git -C "$repo" status --short | wc -l)"
printf '  last commit:       %s\n' "$(git -C "$repo" log -1 --format='%h %s')"

printf '\n%d ok, %d problems\n' "$pass" "$fail"
