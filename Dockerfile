ARG ALPINE_VERSION=3.19
ARG GOST_VERSION=3.0.0-rc10
ARG LYREBIRD_VERSION=0.2.0
ARG MEEK_VERSION=0.38.0
ARG SNOWFLAKE_VERSION=2.9.2

FROM --platform=${BUILDPLATFORM} gogost/gost:${GOST_VERSION} AS gost
FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} as alpine
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
RUN apk update \
  && apk upgrade \
  && rm -rf /var/cache/apk/*

FROM golang:alpine AS pluggables
ARG LYREBIRD_VERSION
ARG MEEK_VERSION
ARG SNOWFLAKE_VERSION
RUN apk update \
  && apk upgrade \
  && apk add -U --no-cache \
    git \
    bash \
    make \
  && rm -rf /var/cache/apk/*
SHELL ["/bin/bash", "-c"]
RUN <<EOT
  set -ex
  cd /tmp

  # Lyrebird - https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/lyrebird
  wget "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/lyrebird/-/archive/lyrebird-${LYREBIRD_VERSION}/lyrebird-lyrebird-${LYREBIRD_VERSION}.tar.gz"
  tar -xvf lyrebird-lyrebird-${LYREBIRD_VERSION}.tar.gz
  pushd lyrebird-lyrebird-${LYREBIRD_VERSION} || exit 1
  make build -e VERSION=${LYREBIRD_VERSION}
  cp ./lyrebird /usr/local/bin
  popd || exit 1

  # Meek - https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/meek
  wget "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/meek/-/archive/v${MEEK_VERSION}/meek-v${MEEK_VERSION}.tar.gz"
  tar -xvf meek-v${MEEK_VERSION}.tar.gz
  pushd meek-v0.38.0/meek-client || exit 1
  make meek-client
  cp ./meek-client /usr/local/bin
  popd || exit 1

  # Snowflake
  wget "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake/-/archive/v${SNOWFLAKE_VERSION}/snowflake-v${SNOWFLAKE_VERSION}.tar.gz"
  tar -xvf snowflake-v${SNOWFLAKE_VERSION}.tar.gz
  pushd snowflake-v${SNOWFLAKE_VERSION}/client || exit 1
  go get -v
  go build -v -o /usr/local/bin/snowflake-client .
  popd || exit 1

  cp -rv /go/bin /usr/local/bin
  rm -rf /go
  rm -rf /tmp/*
EOT

FROM alpine AS base
RUN apk add -U --no-cache \
  bash \
  screen \
  curl \
  nyx \
  tor \
  && rm -rf /var/cache/apk/*

FROM base
ARG MEEK_VERSION
ENV MEEK_VERSION=${MEEK_VERSION}
COPY --from=pluggables /usr/local/bin/lyrebird /usr/local/bin/lyrebird
COPY --from=pluggables /usr/local/bin/meek-client /usr/local/bin/meek-client
COPY --from=pluggables /usr/local/bin/snowflake-client /usr/local/bin/snowflake-client
COPY --from=gost /bin/gost /usr/local/bin/gost

RUN mkdir -p /etc/tor/torrc.d /var/log/gogost

RUN addgroup -S torproxy \
  && adduser -S -G torproxy torproxy \
  && mkdir -p /var/lib/tor \
  && chown -R torproxy:torproxy /var/lib/tor /etc/tor

COPY internal /etc/torproxy/internal
COPY scripts/* /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown torproxy:torproxy /entrypoint.sh
RUN chmod -R +x /usr/local/bin/

HEALTHCHECK --interval=60s --timeout=5s --start-period=20s --retries=3 \
  CMD health | grep -q 'OK'
VOLUME ["/etc/torrc.d", "/var/lib/tor"]
ENTRYPOINT ["/entrypoint.sh"]
