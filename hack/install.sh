#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

USE_DOCKER=${USE_DOCKER:-"0"}

export REPO_ROOT_PATH=${REPO_ROOT_PATH:-"/opt/rpmrepo"}

NGINX_VERSION=1.26.1
RELEASE=2
DIST=${DIST:-"el8"}
ARCH=${ARCH:-"x86_64"}

export SERVER_NAME=${SERVER_NAME:-"localhost"}

RPMSYNC_MODULE=rpmsync
# export GH_TOKEN=${GH_TOKEN:-""}
# export GH_TOKEN_FILE=${GH_TOKEN_FILE:-".gh_token.txt"}

#export NGCONF_DATADIR=/etc/nginx/conf.d/*.conf

export STOPNG_ONINSTALL=${STOPNG_ONINSTALL:-"0"}

PROJECT_PATH=$(pwd)

install-repostore() {
  cd "${RPMSYNC_MODULE}"
  make install-repoall
  cd "${PROJECT_PATH}"
}

install-reposerver() {
  if rpm -q "nginx-${NGINX_VERSION}" &> /dev/null; then
    echo "Nginx is already installed!"
    return 0
  fi

  if [[ "1" == "${STOPNG_ONINSTALL}" ]]; then
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

  rpm -ivh "${REPO_ROOT_PATH}/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION}-${RELEASE}.${DIST}.${ARCH}.rpm"

  if ! rpm -q "nginx-${NGINX_VERSION}" &> /dev/null; then
    echo "nginx not installed!"
    exit 1
  fi
}

install-repoconf() {
  local repo_conf_name="default"
  if [[ "${SERVER_NAME}" != "localhost" ]]; then
    repo_conf_name=${SERVER_NAME}
  fi
  bashutils/render.sh conf/repo.conf.tmpl "conf/${repo_conf_name}.conf"
  trap 'rm -rf "conf/${repo_conf_name}.conf"' EXIT
  install -D -m 644 "conf/${repo_conf_name}.conf" "/etc/nginx/conf.d/${repo_conf_name}.conf" 
  nginx -t
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
