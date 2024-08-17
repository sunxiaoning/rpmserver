#!/bin/bash
#set -x
set -o nounset
set -o errexit
set -o pipefail

start-reposerver() {
  if systemctl is-active --quiet nginx; then
    echo "Service nginx is already started!"
    return 0
  fi
  setsenginx
  systemctl start nginx
  if ! systemctl is-active --quiet nginx; then
    echo "Nginx is not running!"
    exit 1
  fi
}

setsenginx() {
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
  echo "Error: Service nginx is not stopped properly. Current status: ${service_status}."
  exit 1
}


main() {
    case "${1-}" in
    start)
        start-reposerver
        ;;
    reload)
        reload-reposerver
        ;;
    stop)
        stop-reposerver
        ;;
    *)
        echo "Action not support! start/reload/stop only!"
    esac
}

main "$@"
