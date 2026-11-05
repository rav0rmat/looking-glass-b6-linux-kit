#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

SOURCE_DIR="$KIT_ROOT/.upstream/LookingGlass"
BUILD_DIR="$KIT_ROOT/build/client"
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
apply_patch "$SOURCE_DIR/repos/PureSpice" "$KIT_ROOT/patches/01-purespice-linux-clipboard.patch"
apply_patch "$SOURCE_DIR/repos/PureSpice" "$KIT_ROOT/patches/02-purespice-ignore-primary-selection.patch"

cmake -S "$SOURCE_DIR/client" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$BUILD_DIR" --parallel "$(nproc)"
[[ -x "$BUILD_DIR/looking-glass-client" ]] || die "Client binary was not produced"

if ((INSTALL)); then
  need_cmd sudo
  sudo install -m 0755 "$BUILD_DIR/looking-glass-client" /usr/local/bin/looking-glass-client
  log "Client installed in /usr/local/bin; user service was NOT restarted"
else
  log "Client built: $BUILD_DIR/looking-glass-client"
  log "Run again with --install for explicit installation"
fi
