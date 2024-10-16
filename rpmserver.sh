#!/bin/bash

CONTEXT_DIR=$(dirname "$(realpath "${BASH_SOURCE}")")
SCRIPT_NAME=$(basename "$0")

. ${CONTEXT_DIR}/bashutils/basicenv.sh

OPS_SH_DIR="${CONTEXT_DIR}/ops"

. "${CONTEXT_DIR}/ops/env.sh"

. "${OPS_SH_DIR}/install.sh"

. "${OPS_SH_DIR}/run.sh"

. "${OPS_SH_DIR}/uninstall.sh"

trap __terminate INT TERM
trap __cleanup EXIT

TEMP_FILES=()

run-reposerver() {
  install-reposerver
  install-repoconf
  start-reposerver
}

autorun-reposerver() {
  install-repostore
  run-reposerver
}

main() {
  case "${1-}" in
  install-repostore)
    install-repostore
    ;;
  install-reposerver)
    install-reposerver
    ;;
  install-repoconf)
    install-repoconf
    ;;
  start-reposerver)
    start-reposerver
    ;;
  run-reposerver)
    run-reposerver
    ;;
  autorun-reposerver)
    autorun-reposerver
    ;;
  reload-reposerver)
    reload-reposerver
    ;;
  stop-reposerver)
    stop-reposerver
    ;;
  uninstall-reposerver)
    uninstall-reposerver
    ;;
  *)
    echo "The operation: ${1-} is not supported!"
    exit 1
    ;;
  esac
}

terminate() {
  echo "terminating..."
}

cleanup() {
  if [[ "${#TEMP_FILES[@]}" -gt 0 ]]; then
    echo "Cleaning temp_files...."

    for temp_file in "${TEMP_FILES[@]}"; do
      rm -f "${temp_file}" || true
    done
  fi
}

main "$@"
