#!/bin/bash

current_socks_port() {
  get_torrc_option "SocksPort"
}
