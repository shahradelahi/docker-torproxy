#!/bin/bash

DNSMASQ_CONFIG=/etc/dnsmasq.d/tor-dns.conf

setup_dns() {
  local _TOR_DNS_PORT="$(get_torrc_option "DNSPort")"
  if [ -z "$_TOR_DNS_PORT" ]; then
    log ERROR "DNSPort is not set in ${TOR_CONFIG}"
    exit 1
  fi

  if echo "$_TOR_DNS_PORT" | grep -q ":"; then
    _TOR_DNS_PORT="$(echo "$_TOR_DNS_PORT" | awk -F: '{print $2}')"
  fi

  # DNS must be a number
  if ! [[ "$_TOR_DNS_PORT" =~ ^[0-9]+$ ]]; then
    log ERROR "DNSPort options is malformed."
    exit 1
  fi

  log NOTICE "Setting up Dnsmasq to use Tor DNS on port ${_TOR_DNS_PORT}"

  _IFACE="$(ip route show default | awk '/default/ {print $5}')"

  tee /etc/resolv.conf &> /dev/null << EOF
# Generated by TorProxy; DO NOT EDIT
nameserver 127.0.0.1
option allow-domains *.onion
search .
EOF

  tee "$DNSMASQ_CONFIG" &> /dev/null << EOF
pid-file=/var/run/dnsmasq.pid
interface=${_IFACE}
user=dnsmasq
group=dnsmasq
bind-dynamic
no-resolv
no-poll
no-negcache
bogus-priv
domain-needed
cache-size=1500
min-port=4096
server=127.0.0.1#${_TOR_DNS_PORT}
server=::1#${_TOR_DNS_PORT}
log-facility=/var/log/dnsmasq/dnsmasq.log
EOF
  mkdir -p /var/log/dnsmasq
  dnsmasq
}
