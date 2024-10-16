start-reposerver() {
  if systemctl is-active --quiet nginx; then
    echo "Service nginx is already started!"
    return 0
  fi

  if ! rpm -q "${NGINX_APP_NAME}-${NGINX_VERSION}" &>/dev/null; then
    echo "${NGINX_APP_NAME}-${NGINX_VERSION} has not been installed yet!" >&2
    exit 1
  fi

  setsenginx

  systemctl start nginx

  if ! systemctl is-active --quiet nginx; then
    echo "Nginx is not running!" >&2
    exit 1
  fi
}

setsenginx() {
  status=$(sestatus | grep 'SELinux status' | awk '{print $3}')
  if [ "$status" == "disabled" ]; then
    echo "SELinux is disabled, skip setsehttpd_t."
    return 0
  fi
  setsehttpd_t
}

setsehttpd_t() {
  if semanage permissive -l | grep -q httpd_t; then
    return 0
  fi
  echo "Adding httpd_t to permissive mode."
  semanage permissive -a httpd_t
}

reload-reposerver() {
  if ! systemctl is-active --quiet nginx; then
    echo "Service nginx is not running!" >&2
    exit 1
  fi

  echo "Reload service nginx..."

  systemctl reload nginx
}

stop-reposerver() {
  local service_status=$(systemctl is-active nginx 2>/dev/null || true)
  if [[ "${service_status}" == "inactive" ]] || [[ "${service_status}" == "dead" ]]; then
    echo "Service nginx is already stopped!"
    return 0
  fi

  systemctl stop nginx

  service_status=$(systemctl is-active nginx 2>/dev/null || true)
  if [[ "${service_status}" == "inactive" ]] || [[ "${service_status}" == "dead" ]]; then
    return 0
  fi
  echo "Error: Service nginx is not stopped properly. Current status: ${service_status}." >&2
  exit 1
}
