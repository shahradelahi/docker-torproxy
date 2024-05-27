#!/usr/bin/env bash

set -e

TOR_CONFIG_DIR="${TOR_CONFIG_DIR:-/etc/tor}"
TOR_CONFIG="${TOR_CONFIG_DIR}/torrc"

source /etc/torproxy/internal/index.sh
setup_logrotate

# If command starts with nyx, run nyx
if [ "${1}" = 'nyx' ]; then
  shift
  exec nyx "$@"
fi

screen -wipe &> /dev/null || true

if [ ! -f "${TOR_CONFIG}" ]; then
  generate_tor_config
else
  log NOTICE "Using existing tor config file at ${TOR_CONFIG}"
fi
load_tor_env
setup_dns

sleep 1
echo -e "\n======================== Versions ========================"
echo -e "Alpine: \c" && cat /etc/alpine-release
echo -e "Tor: \c" && tor --version | head -n 1 | awk '{print $3}' | sed 's/.$//'
echo -e "Lyrebird: \c" && lyrebird -version
echo -e "Meek: \c" && echo -e "${MEEK_VERSION:-N/A}"
echo -e "Snowflake: \c" && snowflake-client -version &> ver && head -n 1 ver | awk '{print $2}' && rm ver
echo -e "Gost: \c" && gost -V | cut -d' ' -f2
echo -e "Nyx: \c" && nyx --version | head -n 1 | awk '{print $3}'
echo -e "\n======================= Tor Config ======================="
grep -v "^#" "$TOR_CONFIG" | grep -v "^$"
echo -e "============================================================\n"
sleep 1

start_gost_server "$@"
exec tor -f "$TOR_CONFIG"
