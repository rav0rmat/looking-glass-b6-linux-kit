#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

FORCE=0
ENABLE=0
while (($#)); do
  case "$1" in
    --force) FORCE=1; shift ;;
    --enable) ENABLE=1; shift ;;
    -h|--help)
      printf 'Usage: %s [--force] [--enable]\n' "$0"
      exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -x /usr/local/bin/looking-glass-client ]] || log "Warning: /usr/local/bin/looking-glass-client is not installed yet"
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}
install -d -m 0755 "$CONFIG_DIR/looking-glass" "$CONFIG_DIR/systemd/user"

install_file() {
  local src=$1 dst=$2
  if [[ -e "$dst" ]] && (( ! FORCE )); then
    log "Preserving existing configuration: $dst"
  else
    install -m 0644 "$src" "$dst"
    log "Installed: $dst"
  fi
}

install_file "$KIT_ROOT/config/host/client.ini" "$CONFIG_DIR/looking-glass/client.ini"
install_file "$KIT_ROOT/config/host/looking-glass-client.service" "$CONFIG_DIR/systemd/user/looking-glass-client.service"

if ((ENABLE)); then
  need_cmd systemctl
  systemctl --user daemon-reload
  systemctl --user enable looking-glass-client.service
  log "Autostart enabled; client was NOT started or restarted"
else
  log "Files installed; enable explicitly with --enable"
fi
