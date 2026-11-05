#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

FORCE=0
while (($#)); do
  case "$1" in
    --force) FORCE=1; shift ;;
    -h|--help)
      printf 'Usage: %s [--force]\n' "$0"
      exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -x /usr/local/bin/looking-glass-host ]] || log "Warning: /usr/local/bin/looking-glass-host is not installed yet"
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}
AUTOSTART_DIR="$CONFIG_DIR/autostart"
install -d -m 0755 "$AUTOSTART_DIR"
HOST_FILE="$AUTOSTART_DIR/looking-glass-host.desktop"
AGENT_FILE="$AUTOSTART_DIR/spice-vdagent.desktop"

if [[ -e "$HOST_FILE" ]] && (( ! FORCE )); then
  log "Preserving existing configuration: $HOST_FILE"
else
  sed "s|@GUEST_HOME@|$HOME|g" "$KIT_ROOT/config/guest/looking-glass-host.desktop.template" > "$HOST_FILE"
  chmod 0644 "$HOST_FILE"
  log "Installed: $HOST_FILE"
fi

if [[ -e "$AGENT_FILE" ]] && (( ! FORCE )); then
  log "Preserving existing configuration: $AGENT_FILE"
else
  install -m 0644 "$KIT_ROOT/config/guest/spice-vdagent.desktop" "$AGENT_FILE"
  log "Installed: $AGENT_FILE"
fi

log "Autostart will be used at the next graphical login"
