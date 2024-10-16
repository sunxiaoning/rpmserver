STOP_SERV_ON_UNINSTALL=${STOP_SERV_ON_UNINSTALL:-"0"}

CLEAN_DATA_ON_UNINSTALL=${CLEAN_DATA_ON_UNINSTALL:-"0"}

uninstall-reposerver() {
  uninstall-reposerver-rpm
  clean-ngconf-datadir
}

clean-ngconf-datadir() {
  if [[ "1" == "${CLEAN_DATA_ON_UNINSTALL}" ]]; then
    echo "Clean old ngconf datadir ..."
    rm -rf ${NGCONF_DATADIR}/*.conf
  fi
}

uninstall-reposerver-rpm() {
  if ! rpm -q "nginx-${NGINX_VERSION}" &>/dev/null; then
    echo "Nginx rpm is not exists, the operation is skipped!"
    return 0
  fi

  if [[ "1" == "${STOP_SERV_ON_UNINSTALL}" ]]; then
    stop-reposerver
  else
    local service_status=$(systemctl is-active nginx 2>/dev/null || true)
    if [[ "${service_status}" != "inactive" ]] && [[ "${service_status}" != "dead" ]]; then
      echo "Service nginx has not been shutdown completed!"
      exit 1
    fi
  fi

  rpm -evh "nginx-${NGINX_VERSION}"

  if rpm -q "nginx-${NGINX_VERSION}" &>/dev/null; then
    echo "Remove nginx failed!" >&2
    exit 1
  fi
}
