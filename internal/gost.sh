#!/bin/bash

current_socks_port() {
  get_torrc_option "SocksPort"
}

start_gost_server() {
  local _TOR_SOCKS_PORT="$(current_socks_port)"
  local _SCREEN_NAME="gost"

  # Kill previous session
  if screen -list | grep -q "${_SCREEN_NAME}"; then
    screen -S "${_SCREEN_NAME}" -X quit
  fi

  screen -dmS "${_TOR_SOCKS_PORT}" -h 1000 \
    bash -c "gost -F socks5://127.0.0.1:${_TOR_SOCKS_PORT} ${*}"
}
