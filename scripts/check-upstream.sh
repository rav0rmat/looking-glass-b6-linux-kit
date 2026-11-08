#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"
need_cmd git

remote_commit() {
  local repository=$1 ref=$2 attempt output
  for attempt in 1 2 3; do
    if (( attempt == 1 )); then
      output=$(git ls-remote "$repository" "$ref") && break
    else
      output=$(git -c http.version=HTTP/1.1 ls-remote "$repository" "$ref") && break
    fi
    sleep $((attempt * 2))
  done
  [[ -n "${output:-}" ]] || return 1
  awk 'NR==1 {print $1}' <<< "$output"
}

LG_REMOTE=$(remote_commit "$LG_REPOSITORY" "refs/tags/$LG_BRANCH^{}") ||
  die "Could not read upstream tag $LG_BRANCH"
PS_REMOTE=$(remote_commit "$PURESPICE_REPOSITORY" HEAD) || die "Could not read PureSpice HEAD"

printf 'Looking Glass B6: pinned=%s upstream=%s\n' "$LG_COMMIT" "$LG_REMOTE"
printf 'PureSpice HEAD:   pinned=%s upstream=%s\n' "$PURESPICE_COMMIT" "$PS_REMOTE"

if [[ "$LG_REMOTE" != "$LG_COMMIT" ]]; then
  printf 'LOOKING_GLASS_UPDATE=yes\n'
else
  printf 'LOOKING_GLASS_UPDATE=no\n'
fi
if [[ "$PS_REMOTE" != "$PURESPICE_COMMIT" ]]; then
  printf 'PURESPICE_UPDATE=yes (compare the submodules required by B6 first)\n'
else
  printf 'PURESPICE_UPDATE=no\n'
fi
printf 'No local source or installation was modified.\n'
