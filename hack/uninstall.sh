#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

. hack/env.sh

NGINX_VERSION=1.26.1

NGCONF_DATADIR=/etc/nginx/conf.d/*.conf

CLEAN_DATA_ON_UNINSTALL=${CLEAN_DATA_ON_UNINSTALL:-"0"}
STOP_SERV_ON_UNINSTALL=${STOP_SERV_ON_UNINSTALL:-"0"}

uninstall-reposerver() {

  # TODO check status ??

  if [[ "1" == "${STOP_SERV_ON_UNINSTALL}" ]]; then
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

  if [[ "1" == "${CLEAN_DATA_ON_UNINSTALL}" ]]; then
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
