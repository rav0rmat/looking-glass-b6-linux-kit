#!/usr/bin/env bash
set -euo pipefail
DISPLAY=${DISPLAY:-:0}
export DISPLAY
FAILED=0

check_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; FAILED=1; }; }
for cmd in xrandr pgrep; do check_cmd "$cmd"; done

if [[ -c /dev/kvmfr0 ]]; then
  echo "OK: /dev/kvmfr0"
  ls -l /dev/kvmfr0
else
  echo "ERROR: /dev/kvmfr0 is missing"
  FAILED=1
fi

if pgrep -f '[l]ooking-glass-host' >/dev/null; then
  echo "OK: looking-glass-host process"
else
  echo "ERROR: looking-glass-host process is not running"
  FAILED=1
fi
for process in spice-vdagent spice-vdagentd; do
  if pgrep -x "$process" >/dev/null; then echo "OK: $process process"; else echo "ERROR: $process process is not running"; FAILED=1; fi
done

if command -v xrandr >/dev/null 2>&1; then
  xrandr --current | grep -E '\*|connected' || FAILED=1
fi
if command -v pactl >/dev/null 2>&1; then
  pactl info | grep -E 'Server Name|Default Sink' || FAILED=1
else
  echo "Note: install pulseaudio-utils for audio verification"
fi
if command -v ip >/dev/null 2>&1; then
  ip -brief address show scope global
  ip route show default
fi

printf 'DISPLAY=%s\n' "$DISPLAY"
exit "$FAILED"
