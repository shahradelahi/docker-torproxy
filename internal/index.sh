#!/bin/bash

source /etc/torproxy/internal/screen.sh
source /etc/torproxy/internal/tor.sh
source /etc/torproxy/internal/dns.sh
source /etc/torproxy/internal/gost.sh

function uppercase() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

# convert screaming snake case to camel case
function to_camel_case() {
  echo "${1}" | awk -F_ '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1' OFS=""
}

function log() {
  # Feb 20 16:48:35 UTC [notice] message
  echo -e "$(date +"%b %d %H:%M:%S %Z") [$(uppercase "$1")] $2"
}

function setup_logrotate() {
  tee "/etc/logrotate.d/rotator" &> /dev/null << EOF
/var/log/dnsmasq/dnsmasq.log
/var/log/gogost/*.log {
  size 1M
  rotate 3
  missingok
  notifempty
  create 0640 root adm
  copytruncate
}
EOF
  crond
}
