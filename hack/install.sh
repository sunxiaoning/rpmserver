#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

. hack/env.sh

export REPO_LOCAL_ROOT_PATH=${REPO_LOCAL_ROOT_PATH:-/opt/rpmrepo}
export REPO_SERVER_NAME=${REPO_SERVER_NAME:-"localhost"}

REPO_CONF_NAME="default"

NGINX_VERSION=1.26.1
RELEASE=2
DIST=${DIST:-"el8"}
ARCH=${ARCH:-"x86_64"}

RPMSYNC_MODULE=rpmsync
# export GH_TOKEN=${GH_TOKEN:-""}
# export GH_TOKEN_FILE=${GH_TOKEN_FILE:-".gh_token.txt"}

#export NGCONF_DATADIR=/etc/nginx/conf.d/*.conf

STOP_SERV_ON_INSTALL=${STOP_SERV_ON_INSTALL:-"0"}


PROJECT_PATH=$(pwd)

install-repostore() {
  cd "${RPMSYNC_MODULE}"
  make install-repoall
  cd "${PROJECT_PATH}"
}

install-reposerver() {
  check-repolocalroot
  check-nginxrpm-exists
  if rpm -q "nginx-${NGINX_VERSION}" &> /dev/null; then
    echo "Nginx is already installed!"
    return 0
  fi

  if [[ "1" == "${STOP_SERV_ON_INSTALL}" ]]; then
    hack/run.sh stop
  else
    local service_status=$(systemctl is-active nginx 2>/dev/null || true)
    if [[ "${service_status}" != "inactive" ]] && [[ "${service_status}" != "dead" ]]; then
      echo "Service nginx has not been shutdown completed!"
      exit 1
    fi
  fi

  if rpm -q "nginx" &> /dev/null; then
    echo "Find old nginx pkg installed, abort!"
    exit 1
  fi

  rpm -ivh "${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION}-${RELEASE}.${DIST}.${ARCH}.rpm"

  if ! rpm -q "nginx-${NGINX_VERSION}" &> /dev/null; then
    echo "nginx not installed!"
    exit 1
  fi
}

check-nginxrpm-exists() {
  if [ ! -d "${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}" ]; then
    echo "Dir: ${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION} not exists!" >&2
    exit 1
  fi
  if [ ! -f "${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION}-${RELEASE}.${DIST}.${ARCH}.rpm" ]; then
    echo "RPM file: ${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION}-${RELEASE}.${DIST}.${ARCH}.rpm not exists!" >&2
    exit 1
  fi
}

install-repoconf() {
  check-repolocalroot
  if [[ "${REPO_SERVER_NAME}" != "localhost" ]]; then
    REPO_CONF_NAME="${REPO_SERVER_NAME}"
  fi
  bashutils/render.sh conf/repo.conf.tmpl "conf/${REPO_CONF_NAME}.conf"
  trap 'rm -rf "conf/${REPO_CONF_NAME}.conf"' EXIT
  install -D -m 644 "conf/${REPO_CONF_NAME}.conf" "/etc/nginx/conf.d/${REPO_CONF_NAME}.conf" 
  nginx -t
}

check-repolocalroot() {
  if [ ! -d "${REPO_LOCAL_ROOT_PATH}" ]; then
    echo "REPO_LOCAL_ROOT: ${REPO_LOCAL_ROOT_PATH} not exists!" >&2
    exit 1
  fi
  if [ -z "$(ls -A ${REPO_LOCAL_ROOT_PATH})" ]; then 
    echo "REPO_LOCAL_ROOT Dir: ${REPO_LOCAL_ROOT_PATH} is empty!" >&2
    exit 1
  fi
}


main() {
  if [[ "1" == "${USE_DOCKER}" ]]; then
    echo "Begin to build with docker."
    case "${1-}" in
    repostore)
      install-repostore-docker
      ;;
    reposerver)
      install-reposerver-docker
      ;;
    repoconf)
      install-repoconf-docker
      ;;
    *)
      install-repostore-docker
      ;;
    esac
  else
    echo "Begin to build in the local environment."
    case "${1-}" in
    repostore)
      install-repostore
      ;;
    reposerver)
      install-reposerver
      ;;
    repoconf)
      install-repoconf
      ;;
    *)
      install-repostore
      ;;
    esac
  fi
}

main "$@"
