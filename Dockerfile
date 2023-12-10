FROM alpine:3.18
LABEL MAINTAINER="Shahrad Elahi <shahrad@litehex.com> (https://github.com/shahradelahi)"

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Update and upgrade packages
RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    bash \
    screen \
    curl \
    tor \
    && rm -rf /var/cache/apk/*

# Install obfs4proxy for Bridges
COPY --from=chriswayg/tor-alpine:latest /usr/local/bin/obfs4proxy /usr/local/bin/obfs4proxy

# Install gogost
COPY --from=gogost/gost:latest /bin/gost /usr/local/bin/gost

# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Init or Copy files
RUN mkdir -p /etc/tor \
    && mkdir -p /etc/torrc.d/ \
    && mkdir -p /var/log/gogost

COPY scripts/* /usr/local/bin/

# Fix permissions
RUN chmod -R +x /usr/local/bin/

# Setup user
RUN addgroup -S torproxy \
    && adduser -S -G torproxy torproxy \
    && chown -R torproxy:torproxy /etc/tor /var/log/gogost /entrypoint.sh

USER torproxy

# Setup healthcheck
HEALTHCHECK --interval=60s --timeout=3s --start-period=20s --retries=3 \
    CMD health | grep -q 'OK'

EXPOSE 1080 8080

VOLUME ["/etc/torrc.d"]

CMD ["-L", "http://:8080", "-L", "socks5://:1080"]

# Build
#   docker build -t litehex/torproxy .

# Run
#   docker run --rm -p 9090:8080 litehex/torproxy
#   docker run --rm -p 9090:8080 -e TOR_SOCKS5_PROXY=host.docker.internal:8080 litehex/torproxy
#   docker run --rm -p 9090:8080 -e TOR_USE_BRIDGE=1 -v "$(pwd)/config/bridges.conf:/etc/torrc.d/bridges.conf" litehex/torproxy

# Test
#   curl -x http://localhost:8118 ip.me
#   curl -x http://localhost:8080 https://check.torproject.org/api/ip
#   curl -x http://localhost:9090 https://check.torproject.org/api/ip
#   curl -x socks5://localhost:9050 http://whatismyipaddress.com/
#   curl https://check.torproject.org/api/ip

# Test in Container
#   curl -x socks5://localhost:1080 https://ip.me
#   curl -x http://localhost:8080 https://ip.me
#   curl --proxy socks5://username:password@localhost:1080 https://ip.me

# Run with volume
#   docker volume create torproxy
#   docker run --rm -v torproxy:/home/torproxy litehex/torproxy
#   docker run --rm -v torproxy:/home/torproxy -e TOR_SOCKS5_PROXY=host.docker.internal:8080 litehex/torproxy
#   docker run --rm -v torproxy:/home/torproxy -v "$(pwd)/config/torrc:/etc/tor/torrc" litehex/torproxy
#   docker run --rm -v torproxy:/home/torproxy -e TOR_EXIT_NODES=us litehex/torproxy
#   docker run --rm -v torproxy:/home/torproxy litehex/torproxy -L socks5://username:password@:1080