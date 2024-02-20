#!/usr/bin/env bash

set -e

TOR_CONFIG_DIR="${PG_CONFIG_DIR:-/etc/tor}"
TOR_CONFIG="${TOR_CONFIG_DIR}/torrc"

source common.sh

# Generate tor config
generate_tor_config() {
  tee "${TOR_CONFIG}" &>/dev/null <<EOF
####### AUTO-GENERATED FILE, DO NOT EDIT #######

VirtualAddrNetwork ${TOR_VIRTUAL_ADDR_NETWORK:-10.192.0.0/10}
#AutomapHostsOnResolve 1

#SOCKSPort 9050 # Default: Bind to localhost:9050 for local connections.
#SOCKSPort 192.168.0.1:9100 # Bind to this address:port too.
${TOR_SOCKS_PORT:+SOCKSPort $TOR_SOCKS_PORT}

#SOCKSPolicy accept 192.168.0.0/16
#SOCKSPolicy accept6 FC00::/7
#SOCKSPolicy reject *
${TOR_SOCKS_POLICY:+SOCKSPolicy $TOR_SOCKS_POLICY}

#HTTPTunnelPort 80
HTTPTunnelPort ${TOR_HTTP_TUNNEL_PORT:-8118}

#DNSPort 53
${TOR_DNS_PORT:+DNSPort $TOR_DNS_PORT}

#Log notice file @LOCALSTATEDIR@/log/tor/notices.log
#Log debug file @LOCALSTATEDIR@/log/tor/debug.log
#Log notice syslog
#Log debug stderr
${TOR_LOG_LEVEL:+Log $TOR_LOG_LEVEL}

#RunAsDaemon 1
${TOR_RUN_AS_DAEMON:+RunAsDaemon $TOR_RUN_AS_DAEMON}

#DataDirectory @LOCALSTATEDIR@/lib/tor
${TOR_DATA_DIRECTORY:+DataDirectory $TOR_DATA_DIRECTORY}

#ControlPort 9051
${TOR_CONTROL_PORT:+ControlPort $TOR_CONTROL_PORT}
#HashedControlPassword 16:872860B76453A77D60CA2BB8C1A7042072093276A3D701AD684053EC4C
${TOR_HASHED_CONTROL_PASSWORD:+HashedControlPassword $TOR_HASHED_CONTROL_PASSWORD}
${TOR_CONTROL_PASSWD:+HashedControlPassword $(tor --hash-password "$TOR_CONTROL_PASSWD")}
#CookieAuthentication 1
${TOR_COOKIE_AUTHENTICATION:+CookieAuthentication $TOR_COOKIE_AUTHENTICATION}

${TOR_USE_BRIDGE:+UseBridges $TOR_USE_BRIDGE}
ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy managed

#Socks5Proxy 127.0.0.1:1080
${TOR_SOCKS5_PROXY:+Socks5Proxy $TOR_SOCKS5_PROXY}

######### Location-hidden Services ##########

#HiddenServiceDir @LOCALSTATEDIR@/lib/tor/hidden_service/
#HiddenServiceDir @LOCALSTATEDIR@/lib/tor/other_hidden_service/
${TOR_HIDDEN_SERVICE_DIR:+HiddenServiceDir $TOR_HIDDEN_SERVICE_DIR}
#HiddenServicePort 80 127.0.0.1:80
#HiddenServicePort 80 127.0.0.1:80
#HiddenServicePort 22 127.0.0.1:22
${TOR_HIDDEN_SERVICE_PORT:+HiddenServicePort $TOR_HIDDEN_SERVICE_PORT}

################ Relays #####################

#ORPort 9001
#ORPort 443 NoListen
#ORPort 127.0.0.1:9090 NoAdvertise
#ORPort [2001:DB8::1]:9050
${TOR_OR_PORT:+ORPort $TOR_OR_PORT}

#Address noname.example.com
${TOR_ADDRESS:+Address $TOR_ADDRESS}

#OutboundBindAddressExit 10.0.0.4
${TOR_OUTBOUND_BIND_ADDRESS_EXIT:+OutboundBindAddressExit $TOR_OUTBOUND_BIND_ADDRESS_EXIT}
#OutboundBindAddressOR 10.0.0.5
${TOR_OUTBOUND_BIND_ADDRESS_OR:+OutboundBindAddressOR $TOR_OUTBOUND_BIND_ADDRESS_OR}

#Nickname ididnteditheconfig
${TOR_NICKNAME:+Nickname $TOR_NICKNAME}

#RelayBandwidthRate 100 KBytes  # Throttle traffic to 100KB/s (800Kbps)
${TOR_RELAY_BANDWIDTH_RATE:+RelayBandwidthRate $TOR_RELAY_BANDWIDTH_RATE}
#RelayBandwidthBurst 200 KBytes # But allow bursts up to 200KB (1600Kb)
${TOR_RELAY_BANDWIDTH_BURST:+RelayBandwidthBurst $TOR_RELAY_BANDWIDTH_BURST}

#AccountingStart month 3 15:00
${TOR_ACCOUNTING_START:+AccountingStart $TOR_ACCOUNTING_START}

#ContactInfo Random Person <nobody AT example dot com>
#ContactInfo 0xFFFFFFFF Random Person <nobody AT example dot com>
${TOR_CONTACT_INFO:+ContactInfo $TOR_CONTACT_INFO}

#DirPort 9030 # what port to advertise for directory connections
#DirPort 80 NoListen
#DirPort 127.0.0.1:9091 NoAdvertise
${TOR_DIR_PORT:+DirPort $TOR_DIR_PORT}
#DirPortFrontPage @CONFDIR@/tor-exit-notice.html
${TOR_DIR_PORT_FRONT_PAGE:+DirPortFrontPage $TOR_DIR_PORT_FRONT_PAGE}

#MyFamily keyid,keyid,...
${TOR_MY_FAMILY:+MyFamily $TOR_MY_FAMILY}

#ExitRelay 1
${TOR_EXIT_RELAY:+ExitRelay $TOR_EXIT_RELAY}

#IPv6Exit 1
${TOR_IPV6_EXIT:+IPv6Exit $TOR_IPV6_EXIT}

#ReducedExitPolicy 1
${TOR_REDUCED_EXIT_POLICY:+ReducedExitPolicy $TOR_REDUCED_EXIT_POLICY}

#ExitPolicy accept *:6660-6667,reject *:* # allow irc ports on IPv4 and IPv6 but no more
#ExitPolicy accept *:119 # accept nntp ports on IPv4 and IPv6 as well as default exit policy
#ExitPolicy accept *4:119 # accept nntp ports on IPv4 only as well as default exit policy
#ExitPolicy accept6 *6:119 # accept nntp ports on IPv6 only as well as default exit policy
#ExitPolicy reject *:* # no exits allowed
${TOR_EXIT_POLICY:+ExitPolicy $TOR_EXIT_POLICY}

#BridgeRelay 1
${TOR_BRIDGE_RELAY:+BridgeRelay $TOR_BRIDGE_RELAY}
#BridgeDistribution none
${TOR_BRIDGE_DISTRIBUTION:+BridgeDistribution $TOR_BRIDGE_DISTRIBUTION}

############### Other options ###############

%include /etc/torrc.d/*.conf

########## END AUTO-GENERATED FILE ##########
EOF

  env_to_config

  # Remove comment line with single Hash
  sed -i '/^#\([^#]\)/d' "${TOR_CONFIG}"

  # Remove options with no value. (KEY[:space:]{...VALUE})
  sed -i '/^[^ ]* $/d' "${TOR_CONFIG}"

  # Remove double empty lines
  sed -i '/^$/N;/^\n$/D' "${TOR_CONFIG}"
}

CUSTOM_TOR_OPTIONS=(
  "TOR_CONTROL_PASSWD"
)

# gets any environment variables that start with TOR_ and adds them to the config file
env_to_config() {
  local added_count=0
  local updated_count=0
  for _env_name in $(env | grep -o "^TOR_[^=]*"); do

    # skip custom options
    if [[ " ${CUSTOM_TOR_OPTIONS[*]} " == *" ${_env_name} "* ]]; then
      continue
    fi

    local env_value="${!_env_name}"

    # remove prefix and convert to camel case
    local option=$(to_camel_case "${_env_name#TOR_}")
    if [ -n "${env_value}" ]; then

      # Check if there is a corresponding option in the torrc file, and update it
      if grep -i -q "^${option}" "${TOR_CONFIG}"; then
        sed -i "s/^${option}.*/${option} ${env_value}/" "${TOR_CONFIG}"
        updated_count=$((updated_count + 1))
      else
        sed -i "s/^############### Other options ###############$/&\n\n${option} ${env_value}/" "${TOR_CONFIG}"
        added_count=$((added_count + 1))
      fi

    fi
  done

  # Add a blank line at the end of the file
  echo "" >>"${TOR_CONFIG}"

  if [ "${added_count}" -gt 0 ] || [ "${updated_count}" -gt 0 ]; then
    echo ""
    log INFO "Added ${added_count} and updated ${updated_count} options from environment variables."
  fi
}

# If command starts with nyx, run nyx
if [ "${1}" = 'nyx' ]; then
  shift
  exec nyx "$@"
fi

# Create torrc file if it doesn't exist
if [ ! -f "${TOR_CONFIG}" ]; then
  generate_tor_config
else
  log INFO "Using existing tor config file at ${TOR_CONFIG}"
fi

sleep 1
echo -e "\n======================== Versions ========================"
echo -e "Alpine: \c" && cat /etc/alpine-release
echo -e "Tor: \c" && tor --version | head -n 1 | awk '{print $3}' | sed 's/.$//'
echo -e "Obfs4proxy: \c" && obfs4proxy -version
echo -e "Gost: \c" && gost -V
echo -e "Nyx: \c" && nyx --version | head -n 1 | awk '{print $3}'
echo -e "\n======================= Tor Config ======================="
#cat "${TOR_CONFIG}" | grep -v "^#" | grep -v "^$"
grep -v "^#" "${TOR_CONFIG}" | grep -v "^$"
echo -e "============================================================\n"
sleep 1

# Run gost service
start-proxy "$@"

# Run tor service
exec tor -f "${TOR_CONFIG}"
