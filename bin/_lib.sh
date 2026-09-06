#!/usr/bin/env bash
# bin/_lib.sh

set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$BIN_DIR/.." && pwd)"
MISE_BIN="${MISE_BIN:-${HOME}/.local/bin/mise}"

cd "$ROOT_DIR"

if [[ -z "${ACTIVEADMIN_REACT_PATH:-}" && -d "$ROOT_DIR/../activeadmin-react/lib" ]]; then
  export ACTIVEADMIN_REACT_PATH="$ROOT_DIR/../activeadmin-react"
fi

run() {
  if [[ -x "$MISE_BIN" ]]; then
    PATH="${HOME}/.local/bin:${PATH}" "$MISE_BIN" exec -- "$@"
  else
    command "$@"
  fi
}

run_exec() {
  if [[ -x "$MISE_BIN" ]]; then
    exec env PATH="${HOME}/.local/bin:${PATH}" "$MISE_BIN" exec -- "$@"
  else
    exec "$@"
  fi
}

heading() {
  printf "\n==> %s\n" "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf "Missing required command: %s\n" "$1" >&2
    return 1
  }
}
