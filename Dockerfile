ARG ALPINE_VERSION=3.19
ARG GOST_VERSION=3.0.0-rc10

ARG BUILDPLATFORM=linux/amd64


FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS alpine
FROM --platform=${BUILDPLATFORM} chriswayg/tor-alpine:latest AS tor
FROM --platform=${BUILDPLATFORM} gogost/gost:${GOST_VERSION} AS gost


FROM alpine AS base

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install obfs4proxy for Bridges
COPY --from=tor /usr/local/bin/obfs4proxy /usr/local/bin/obfs4proxy

# Install gogost
COPY --from=gost /bin/gost /usr/local/bin/gost

# Update and upgrade packages
RUN apk update &&\
  apk upgrade &&\
  # Install packages
  apk add --no-cache \
    bash \
    screen \
    curl \
    nyx \
    tor &&\
  # Clean up
  rm -rf /var/cache/apk/*



FROM base

# To prevent conflict between user choice and the default port, we use a different port
ENV TOR_SOCKS_PORT=59050 \
  TOR_HTTP_TUNNEL_PORT=58118 \
  TOR_TRANS_PORT=58119

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
HEALTHCHECK --interval=60s --timeout=5s --start-period=20s --retries=3 \
    CMD health | grep -q 'OK'

VOLUME ["/etc/torrc.d"]

CMD ["-L", "http://:8080", "-L", "socks://:1080"]

# Build
#   docker buildx build -t litehex/torproxy .

# Run
#   docker run --rm -p 9090:8080 litehex/torproxy
#   docker run --rm -p 9090:8080 -e TOR_SOCKS5_PROXY=host.docker.internal:8080 litehex/torproxy
#   docker run --rm -p 9090:8080 -e TOR_USE_BRIDGE=1 -v "$(pwd)/config/bridges.conf:/etc/torrc.d/bridges.conf" litehex/torproxy

# Test
#   curl -x socks5://localhost:1080 https://ip.me
#   curl -x http://localhost:8080 https://ip.me
#   curl --proxy socks5://username:password@localhost:1080 https://ip.me

# Run with volume
#   docker volume create torproxy
#   docker run --rm -v torproxy:/home/torproxy litehex/torproxy
#   docker run --rm -v torproxy:/home/torproxy -e TOR_SOCKS5_PROXY=host.docker.internal:8080 litehex/torproxy
#   docker run --rm -v torproxy:/home/torproxy -v "$(pwd)/config/torrc:/etc/tor/torrc" litehex/torproxy
#   docker run --rm -v torproxy:/home/torproxy litehex/torproxy -L socks5://username:password@:1080