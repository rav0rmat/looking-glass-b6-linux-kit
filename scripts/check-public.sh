#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
FAILED=0

scan() {
  local description=$1 pattern=$2
  if grep -RInE \
    --exclude-dir=.git \
    --exclude-dir=.upstream \
    --exclude-dir=build \
    --exclude='check-public.sh' \
    -- "$pattern" "$ROOT"; then
    printf 'Potentially non-publishable content: %s\n' "$description" >&2
    FAILED=1
  fi
}

scan 'keys or tokens' 'BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}'
scan 'remaining personal paths or account names' '/home/[A-Za-z0-9._-]+|/Users/[A-Za-z0-9._-]+'
scan 'MAC addresses' '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'
scan 'private IPv4 addresses' '\b(10\.[0-9]{1,3}|192\.168|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}\b'

if ((FAILED)); then
  printf 'Publication check failed. Correct the reported lines.\n' >&2
  exit 1
fi
printf 'Publication check: no blocked patterns found.\n'
