#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

SOURCE_DIR="$KIT_ROOT/.upstream/LookingGlass"
BUILD_DIR="$KIT_ROOT/build/host"
INSTALL=0
while (($#)); do
  case "$1" in
    --source-dir) SOURCE_DIR=$2; shift 2 ;;
    --build-dir) BUILD_DIR=$2; shift 2 ;;
    --install) INSTALL=1; shift ;;
    -h|--help)
      printf 'Usage: %s [--source-dir DIR] [--build-dir DIR] [--install]\n' "$0"
      exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

need_cmd cmake
bash "$SCRIPT_DIR/fetch-source.sh" "$SOURCE_DIR"
cmake -S "$SOURCE_DIR/host" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_XCB=ON
cmake --build "$BUILD_DIR" --parallel "$(nproc)"
[[ -x "$BUILD_DIR/looking-glass-host" ]] || die "Host binary was not produced"

if ((INSTALL)); then
  need_cmd sudo
  sudo install -m 0755 "$BUILD_DIR/looking-glass-host" /usr/local/bin/looking-glass-host
  log "Looking Glass Host installed; capture was NOT restarted"
else
  log "Host built: $BUILD_DIR/looking-glass-host"
  log "Run again with --install for explicit installation"
fi
