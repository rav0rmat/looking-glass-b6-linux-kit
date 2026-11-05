#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

SOURCE_DIR="$KIT_ROOT/.upstream/LookingGlass"
KERNEL=$(uname -r)
DEFAULT_KBUILD=/lib/modules/$KERNEL/build
KBUILD=$DEFAULT_KBUILD
INSTALL=0
while (($#)); do
  case "$1" in
    --source-dir) SOURCE_DIR=$2; shift 2 ;;
    --kbuild) KBUILD=$2; shift 2 ;;
    --install) INSTALL=1; shift ;;
    -h|--help)
      printf 'Usage: %s [--source-dir DIR] [--kbuild DIR] [--install]\n' "$0"
      exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

need_cmd make
[[ -d "$KBUILD" ]] || die "Missing headers for kernel $KERNEL (package linux-headers-$KERNEL) or the specified --kbuild directory"
if ((INSTALL)) && [[ "$KBUILD" != "$DEFAULT_KBUILD" ]]; then
  die "--install is allowed only for the running kernel; do not use --kbuild with --install"
fi
bash "$SCRIPT_DIR/fetch-source.sh" "$SOURCE_DIR"
apply_patch "$SOURCE_DIR" "$KIT_ROOT/patches/03-kvmfr-modern-kernels.patch"

make -C "$KBUILD" M="$SOURCE_DIR/module" modules
[[ -f "$SOURCE_DIR/module/kvmfr.ko" ]] || die "Module kvmfr.ko was not produced"

if ((INSTALL)); then
  need_cmd sudo
  sudo install -D -m 0644 "$SOURCE_DIR/module/kvmfr.ko" "/lib/modules/$KERNEL/extra/kvmfr.ko"
  sudo depmod -a
  sudo install -m 0644 "$KIT_ROOT/config/guest/kvmfr.conf" /etc/modules-load.d/kvmfr.conf
  sudo install -m 0644 "$KIT_ROOT/config/guest/60-kvmfr.rules" /etc/udev/rules.d/60-kvmfr.rules
  sudo udevadm control --reload-rules
  log "KVMFR installed for $KERNEL; load it with: sudo modprobe kvmfr"
  log "Add the guest user to the kvm group, then log out and back in"
else
  log "Module built: $SOURCE_DIR/module/kvmfr.ko"
  log "Run again with --install for explicit installation"
fi
