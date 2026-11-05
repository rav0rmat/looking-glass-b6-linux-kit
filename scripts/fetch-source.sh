#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

SOURCE_DIR=${1:-"$KIT_ROOT/.upstream/LookingGlass"}
CLONED=0
need_cmd git

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  [[ ! -e "$SOURCE_DIR" ]] || die "Directory exists but is not a Git checkout: $SOURCE_DIR"
  mkdir -p "$(dirname "$SOURCE_DIR")"
  log "Cloning Looking Glass $LG_BRANCH"
  for attempt in 1 2 3; do
    if (( attempt == 1 )); then
      git clone --branch "$LG_BRANCH" --single-branch "$LG_REPOSITORY" "$SOURCE_DIR" && break
    else
      git -c http.version=HTTP/1.1 clone --branch "$LG_BRANCH" --single-branch "$LG_REPOSITORY" "$SOURCE_DIR" && break
    fi
    rm -rf "$SOURCE_DIR"
    sleep $((attempt * 2))
    (( attempt < 3 )) || die "Clone failed after three attempts"
  done
  CLONED=1
fi

ACTUAL=$(git -C "$SOURCE_DIR" rev-parse HEAD)
if ((CLONED)) && [[ "$ACTUAL" != "$LG_COMMIT" ]]; then
  git -C "$SOURCE_DIR" checkout --detach "$LG_COMMIT"
  ACTUAL=$(git -C "$SOURCE_DIR" rev-parse HEAD)
fi
[[ "$ACTUAL" == "$LG_COMMIT" ]] || die "Checkout is not $LG_COMMIT; use a new directory without resetting local modifications"

git_retry "$SOURCE_DIR" submodule sync --recursive
git_retry "$SOURCE_DIR" submodule update --init --recursive
PURESPICE_ACTUAL=$(git -C "$SOURCE_DIR/repos/PureSpice" rev-parse HEAD)
[[ "$PURESPICE_ACTUAL" == "$PURESPICE_COMMIT" ]] || die "PureSpice is not at the revision required by B6"

log "Source ready: $SOURCE_DIR"
log "Looking Glass: $LG_COMMIT"
log "PureSpice: $PURESPICE_COMMIT"
