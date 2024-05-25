#!/bin/bash

source /etc/torproxy/internal/tor.sh
source /etc/torproxy/internal/gost.sh

# convert screaming snake case to camel case
function to_camel_case() {
  echo "${1}" | awk -F_ '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1' OFS=""
}

function log() {
  local LEVEL=${1}
  local MESSAGE=${2}
  # Feb 20 16:48:35 UTC [notice] message
  echo -e "$(date +"%b %d %H:%M:%S %Z") [${LEVEL}] ${MESSAGE}"
}
