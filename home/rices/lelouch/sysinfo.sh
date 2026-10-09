#!/bin/sh
# One snapshot of system statistics for the command center.
# Output is in sections, each introduced by a line starting with "@".

echo "@stat"
grep '^cpu' /proc/stat

echo "@freq"
count=$(grep -c '^processor' /proc/cpuinfo)
i=0
while [ "$i" -lt "$count" ]; do
    cat "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" 2>/dev/null || echo 0
    i=$((i + 1))
done

echo "@temp"
for hw in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$hw/name" 2>/dev/null)" = "coretemp" ] || continue
    for input in "$hw"/temp*_input; do
        label=$(cat "$(dirname "$input")/$(basename "$input" _input)_label" 2>/dev/null)
        echo "$label=$(cat "$input")"
    done
done

echo "@mem"
grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SReclaimable|Shmem|SwapTotal|SwapFree):' /proc/meminfo

echo "@top"
ps -eo rss=,comm= | awk '{a[$2] += $1} END {for (k in a) print a[k], k}' | sort -rn | head -n 5

echo "@gpu"
for card in /sys/class/drm/card[0-9]; do
    [ -r "$card/gt_cur_freq_mhz" ] || continue
    echo "cur=$(cat "$card/gt_act_freq_mhz" 2>/dev/null || cat "$card/gt_cur_freq_mhz")"
    echo "max=$(cat "$card/gt_RP0_freq_mhz" 2>/dev/null || cat "$card/gt_max_freq_mhz")"
    echo "rc6=$(cat "$card/power/rc6_residency_ms" 2>/dev/null || cat "$card/gt/gt0/rc6_residency_ms" 2>/dev/null || echo 0)"
    break
done

echo "@df"
df -B1 -x tmpfs -x devtmpfs -x efivarfs -x squashfs -x overlay --output=target,size,used | tail -n +2

echo "@io"
awk '$3 ~ /^(nvme[0-9]+n[0-9]+|sd[a-z]+|mmcblk[0-9]+)$/ {print $3, $6, $10}' /proc/diskstats

echo "@net"
sed 's/:/ /' /proc/net/dev | awk 'NR > 2 && $1 != "lo" {rx += $2; tx += $10} END {print rx + 0, tx + 0}'

echo "@ip"
ip -4 -o addr show scope global | awk '{print $2, $4}'

echo "@gw"
ip route | awk '/^default/ {print $3; exit}'

echo "@bat"
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
if [ -n "$bat" ]; then
    echo "capacity=$(cat "$bat/capacity" 2>/dev/null || echo 0)"
    echo "status=$(cat "$bat/status" 2>/dev/null || echo Unknown)"
    echo "cycles=$(cat "$bat/cycle_count" 2>/dev/null || echo 0)"
    if [ -r "$bat/energy_now" ]; then
        echo "now=$(cat "$bat/energy_now")"
        echo "full=$(cat "$bat/energy_full")"
        echo "design=$(cat "$bat/energy_full_design")"
        echo "power=$(cat "$bat/power_now" 2>/dev/null || echo 0)"
    else
        volt=$(cat "$bat/voltage_now" 2>/dev/null || echo 0)
        echo "now=$(( $(cat "$bat/charge_now" 2>/dev/null || echo 0) * volt / 1000000 ))"
        echo "full=$(( $(cat "$bat/charge_full" 2>/dev/null || echo 0) * volt / 1000000 ))"
        echo "design=$(( $(cat "$bat/charge_full_design" 2>/dev/null || echo 0) * volt / 1000000 ))"
        echo "power=$(( $(cat "$bat/current_now" 2>/dev/null || echo 0) * volt / 1000000 ))"
    fi
fi

echo "@end"
