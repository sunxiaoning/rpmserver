export REPO_ORIGIN_SOURCE=${REPO_ORIGIN_SOURCE:-"0"}

RPMSYNC_MODULE="rpmsync"

RPMSYNC_SH_FILE="${RPMSYNC_MODULE}/rpmsync.sh"

export REPO_LOCAL_ROOT_PATH=${REPO_LOCAL_ROOT_PATH:-/opt/rpmrepo}

export REPO_SERVER_PORT=${REPO_SERVER_PORT:-"80"}
export REPO_SERVER_NAME=${REPO_SERVER_NAME:-"localhost"}

STOP_SERV_ON_INSTALL=${STOP_SERV_ON_INSTALL:-"0"}

DIST="el$(rpm -E %{rhel})"

ARCH=$(uname -m)

REPO_CONF_NAME="default"

ENABLE_SERVICE_ON_INSTALL=${ENABLE_SERVICE_ON_INSTALL:-"1"}

install-repostore() {
  "${RPMSYNC_SH_FILE}" install-repoall
}

install-reposerver() {
  install-reposerver-rpm
  enable-reposerver-service
}

enable-reposerver-service() {
  local enabled_status="$(systemctl is-enabled nginx 2>/dev/null || true)"
  if [[ "${enabled_status}" == "enabled" ]]; then
    echo "Service nginx is already enabled!"
    return 0
  fi

  if [[ "1" == "${ENABLE_SERVICE_ON_INSTALL}" ]]; then
    systemctl enable nginx
  fi

  enabled_status="$(systemctl is-enabled nginx 2>/dev/null || true)"
  if [[ "${enabled_status}" != "enabled" ]]; then
    systemctl enable nginx
  fi
}

install-reposerver-rpm() {
  check-repolocalroot

  check-nginxrpm-exists

  if rpm -q "${NGINX_APP_NAME}-${NGINX_VERSION}" &>/dev/null; then
    echo "${NGINX_APP_NAME}-${NGINX_VERSION} is already installed!"
    return 0
  fi

  if [[ "1" == "${STOP_SERV_ON_INSTALL}" ]]; then
    stop-reposerver
  else
    local service_status=$(systemctl is-active nginx 2>/dev/null || true)
    if [[ "${service_status}" != "inactive" ]] && [[ "${service_status}" != "dead" ]]; then
      echo "Service nginx has not been shutdown completed!"
      exit 1
    fi
  fi

  if rpm -q "${NGINX_APP_NAME}" &>/dev/null; then
    echo "Find old nginx pkg installed, abort!"
    exit 1
  fi

  rpm -ivh "${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION}-${NGINX_RELEASE}.${DIST}.${ARCH}.rpm"

  if ! rpm -q "${NGINX_APP_NAME}-${NGINX_VERSION}" &>/dev/null; then
    echo "${NGINX_APP_NAME}-${NGINX_VERSION} not installed!"
    exit 1
  fi
}

check-nginxrpm-exists() {
  if [ ! -d "${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}" ]; then
    echo "Dir: ${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION} not exists!" >&2
    exit 1
  fi

  if [ ! -f "${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION}-${NGINX_RELEASE}.${DIST}.${ARCH}.rpm" ]; then
    echo "RPM file: ${REPO_LOCAL_ROOT_PATH}/nginx/${NGINX_VERSION}/nginx-${NGINX_VERSION}-${NGINX_RELEASE}.${DIST}.${ARCH}.rpm not exists!" >&2
    exit 1
  fi
}

install-repoconf() {
  check-repolocalroot

  if [[ "${REPO_SERVER_NAME}" != "localhost" ]]; then
    REPO_CONF_NAME="${REPO_SERVER_NAME}"
  fi

  bashutils/render.sh conf/repo.conf.tmpl "conf/${REPO_CONF_NAME}.conf"

  TEMP_FILES+=("conf/${REPO_CONF_NAME}.conf")

  install -D -m 644 "conf/${REPO_CONF_NAME}.conf" "${NGCONF_DATADIR}/${REPO_CONF_NAME}.conf"

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
