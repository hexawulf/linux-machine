#!/usr/bin/env bash
set -euo pipefail

OUT="/home/zk/projects/linux-machine/status.json"
TMP="$(mktemp /home/zk/projects/linux-machine/.status.XXXXXX.json)"

BOOT_EPOCH="$(date -d "$(uptime -s)" +%s)"
NOW_EPOCH="$(date +%s)"
HOSTNAME_="$(hostname)"
KERNEL="$(uname -r)"
. /etc/os-release; OS="${PRETTY_NAME}"
UPTIME_PRETTY="$(uptime -p)"
LOAD="$(cut -d' ' -f1-3 /proc/loadavg)"
CPU="$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo)"
MEM="$(free -m | awk '/^Mem:/{printf "%d / %d MiB", $3, $2}')"
DISK="$(df -h --output=used,size,pcent / | awk 'NR==2{print $1" / "$2" ("$3")"}')"
LOCALE_="${LANG:-en_US.UTF-8}"

printf '{\n  "hostname": "%s",\n  "os": "%s",\n  "kernel": "%s",\n  "cpu": "%s",\n  "mem": "%s",\n  "disk_root": "%s",\n  "locale": "%s",\n  "loadavg": "%s",\n  "uptime_pretty": "%s",\n  "boot_epoch": %s,\n  "generated_epoch": %s\n}\n' \
  "$HOSTNAME_" "$OS" "$KERNEL" "$CPU" "$MEM" "$DISK" "$LOCALE_" "$LOAD" "$UPTIME_PRETTY" "$BOOT_EPOCH" "$NOW_EPOCH" > "$TMP"

mv -f "$TMP" "$OUT"
chmod 644 "$OUT"
