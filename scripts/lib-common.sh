#!/usr/bin/env bash
# Shared functions; load with source, do not execute directly.

KIT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=versions.env
source "$KIT_ROOT/versions.env"

log() { printf '[kit] %s\n' "$*"; }
die() { printf '[kit] ERROR: %s\n' "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

git_retry() {
  local dir=$1
  shift
  local attempt
  for attempt in 1 2 3; do
    if (( attempt == 1 )); then
      git -C "$dir" "$@" && return 0
    else
      git -C "$dir" -c http.version=HTTP/1.1 "$@" && return 0
    fi
    log "Git command failed; retrying ($attempt/3)..."
    sleep $((attempt * 2))
  done
  return 1
}

apply_patch() {
  local dir=$1 patch=$2
  if git -C "$dir" apply --check "$patch" >/dev/null 2>&1; then
    git -C "$dir" apply "$patch"
    log "Applied patch: $(basename "$patch")"
  elif git -C "$dir" apply --reverse --check "$patch" >/dev/null 2>&1; then
    log "Patch already applied: $(basename "$patch")"
  else
    die "Incompatible patch or source with other modifications: $patch"
  fi
}
