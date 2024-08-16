#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

USE_DOCKER=${USE_DOCKER:-"0"}

NGINX_VERSION=1.26.1

export NGCONF_DATADIR=/etc/nginx/conf.d/*.conf

export CLEAN_NGDATA_UNINSTALL=${CLEAN_NGDATA_UNINSTALL:-"0"}
export STOPNG_ONINSTALL=${STOPNG_ONINSTALL:-"0"}

PROJECT_PATH=$(pwd)

uninstall-reposerver() {

  if [[ "1" == "${STOPNG_ONINSTALL}" ]]; then
    hack/run.sh stop
  else
    local service_status=$(systemctl is-active nginx 2>/dev/null || true)
    if [[ "${service_status}" != "inactive" ]] && [[ "${service_status}" != "dead" ]]; then
      echo "Service nginx has not been shutdown completed!"
      exit 1
    fi
  fi

  if rpm -q "nginx-${NGINX_VERSION}" &> /dev/null; then
    rpm -evh "nginx-${NGINX_VERSION}"
  fi

  if rpm -q "nginx-${NGINX_VERSION}" &> /dev/null; then
    echo "Remove nginx failed!" >&2
    exit 1
  fi

  if [[ "1" == "${CLEAN_NGDATA_UNINSTALL}" ]]; then
    echo "Clean old ngconf datadir ..."
    rm -rf ${NGCONF_DATADIR}
  fi
}

main() {
  if [[ "1" == "${USE_DOCKER}" ]]; then
    echo "Begin to build with docker."
    case "${1-}" in
    reposerver)
      uninstall-reposerver-docker
      ;;
    *)
      uninstall-reposerver-docker
      ;;
    esac
  else
    echo "Begin to build in the local environment."
    case "${1-}" in
    reposerver)
      uninstall-reposerver
      ;;
    *)
      uninstall-reposerver
      ;;
    esac
  fi
}

main "$@"
