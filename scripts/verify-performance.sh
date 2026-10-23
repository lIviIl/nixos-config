#!/usr/bin/env bash
# Hardware, performance and network check, with a ping test you can compare before and after a change.
#   bash ~/nixos-config/scripts/verify-performance.sh --baseline    save the ping numbers as "before"
#   bash ~/nixos-config/scripts/verify-performance.sh               run again later: shows before and now
set -u

repo="$HOME/nixos-config"
shell="$repo/home/rices/lelouch/shell"
base="$HOME/.cache/lelouch/ping-baseline.txt"
mkdir -p "$(dirname "$base")"
pass=0
fail=0

have() { command -v "$1" > /dev/null 2>&1; }
section() { printf '\n== %s\n' "$1"; }

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

wifi="$(nmcli -t -f DEVICE,TYPE device 2> /dev/null | awk -F: '$2 == "wifi" {print $1; exit}')"
gateway="$(ip route 2> /dev/null | awk '/^default/ {print $3; exit}')"

section "Hardware"
printf '  cpu:       %s\n' "$(lscpu 2> /dev/null | sed -n 's/^Model name:[[:space:]]*//p' | head -n 1)"
printf '  threads:   %s\n' "$(nproc)"
printf '  memory:    %s\n' "$(free -h | awk '/^Mem:/ {print $2 " total, " $7 " available"}')"
printf '  disk:      %s\n' "$(lsblk -dno NAME,SIZE,ROTA,MODEL 2> /dev/null | head -n 2 | tr '\n' ';')"
printf '  kernel:    %s\n' "$(uname -r)"
if have lspci; then
  printf '  graphics:  %s\n' "$(lspci 2> /dev/null | grep -iE 'vga|display' | head -n 1 | cut -d: -f3-)"
  printf '  wifi chip: %s\n' "$(lspci 2> /dev/null | grep -iE 'network|wireless' | head -n 1 | cut -d: -f3-)"
else
  printf '  (lspci arrives with the rebuild)\n'
fi
if [ -n "$wifi" ]; then
  printf '  wifi:      %s, driver %s\n' "$wifi" "$(basename "$(readlink -f "/sys/class/net/$wifi/device/driver" 2> /dev/null)")"
fi

section "CPU and power"
printf '  frequency driver: %s\n' "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2> /dev/null)"
printf '  governor:         %s\n' "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2> /dev/null)"
printf '  energy bias:      %s\n' "$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2> /dev/null)"
printf '  power profile:    %s\n' "$(powerprofilesctl get 2> /dev/null)"
printf '  on AC:            %s\n' "$(cat /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online 2> /dev/null | head -n 1)"
printf '  scheduler state:  %s %s\n' "$(cat /sys/kernel/sched_ext/state 2> /dev/null || echo 'no sched_ext')" "$(cat /sys/kernel/sched_ext/root/ops 2> /dev/null)"
have sensors && printf '  temperatures:     %s\n' "$(sensors 2> /dev/null | grep -E 'Package id 0|Tctl|temp1' | head -n 2 | awk '{print $1, $2, $3, $4}' | tr '\n' ';')"

section "Memory"
printf '  swap devices:\n'
swapon --show 2> /dev/null | sed 's/^/    /'
printf '  swappiness: %s   page-cluster: %s\n' "$(sysctl -n vm.swappiness)" "$(sysctl -n vm.page-cluster)"

section "Network"
printf '  congestion control: %s   queue: %s\n' "$(sysctl -n net.ipv4.tcp_congestion_control)" "$(sysctl -n net.core.default_qdisc)"
if have iw && [ -n "$wifi" ]; then
  printf '  power save: %s\n' "$(iw dev "$wifi" get power_save 2> /dev/null)"
  printf '  country:    %s\n' "$(iw reg get 2> /dev/null | grep -m 1 country)"
  iw dev "$wifi" link 2> /dev/null | grep -E 'freq|signal|bitrate' | sed 's/^[[:space:]]*/  /'
else
  printf '  (iw arrives with the rebuild)\n'
fi

ping_line() {
  # min/avg/max/mdev in ms, and packet loss
  local out
  out="$(ping -c 30 -i 0.2 -q "$1" 2> /dev/null)"
  printf '%s, loss %s' "$(printf '%s' "$out" | sed -n 's/^rtt [^=]*= //p')" "$(printf '%s' "$out" | grep -oE '[0-9.]+% packet loss' | head -n 1)"
}

section "Ping (30 packets each; min/avg/max/mdev, lower is better, mdev is the jitter)"
now_gateway=""
now_internet=""
[ -n "$gateway" ] && now_gateway="$(ping_line "$gateway")"
now_internet="$(ping_line 1.1.1.1)"
printf '  router   now:    %s\n' "${now_gateway:-no gateway found}"
printf '  internet now:    %s\n' "$now_internet"
if [ "${1:-}" = "--baseline" ]; then
  printf 'router=%s\ninternet=%s\n' "$now_gateway" "$now_internet" > "$base"
  printf '  (saved as "before")\n'
elif [ -f "$base" ]; then
  printf '  router   before: %s\n' "$(sed -n 's/^router=//p' "$base")"
  printf '  internet before: %s\n' "$(sed -n 's/^internet=//p' "$base")"
fi

if [ "${1:-}" != "--baseline" ]; then
  section "Checks"
  check "Zen kernel"                       sh -c 'uname -r | grep -qi zen'
  check "zram swap active"                 sh -c 'zramctl 2> /dev/null | grep -q zram'
  check "BBR in use"                       sh -c '[ "$(sysctl -n net.ipv4.tcp_congestion_control)" = bbr ]'
  check "Wi-Fi power save off"             sh -c "iw dev '$wifi' get power_save 2> /dev/null | grep -qi 'off'"
  check "scx scheduler running"            systemctl is-active --quiet scx
  check "sched_ext enabled"                sh -c '[ "$(cat /sys/kernel/sched_ext/state 2> /dev/null)" = enabled ]'
  check "thermald running"                 systemctl is-active --quiet thermald
  check "earlyoom running"                 systemctl is-active --quiet earlyoom
  check "systemd-resolved running"         systemctl is-active --quiet systemd-resolved
  check "fstrim timer active"              systemctl is-active --quiet fstrim.timer
  check "hardware video decoding (VA-API)" sh -c 'vainfo 2>&1 | grep -q VAProfile'
  check "performance.nix is imported"      grep -q 'modules/nixos/performance.nix' "$repo/hosts/nixos/default.nix"
  check "network.nix is imported"          grep -q 'modules/nixos/network.nix' "$repo/hosts/nixos/default.nix"
  check "bar no longer triggers scans"     grep -q -- '--rescan no' "$shell/Net.qml"
  check "Connect tab no longer triggers scans" grep -q -- '"--rescan", "no"' "$shell/ConnectPage.qml"

  section "Warnings from the services involved (newest last)"
  journalctl -b -p warning --no-pager -u scx -u NetworkManager -u thermald -u earlyoom -u systemd-resolved 2> /dev/null | tail -n 8

  printf '\n%d ok, %d problems\n' "$pass" "$fail"
fi
