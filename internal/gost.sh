#!/bin/bash

current_socks_port() {
  get_torrc_option "SocksPort"
}

start_gost_server() {
  local _TOR_SOCKS_PORT="$(current_socks_port)"

  kill_screen "gogost"

  screen -dmS "gogost" \
    -L -Logfile /var/log/gogost/gogost.log \
    bash -c "gost -F socks5://127.0.0.1:${_TOR_SOCKS_PORT} ${*}"
}
