# Docker TorProxy

> A stable version of Tor for with tools for creating a proxy server.

---

- [Features](#features)
- [Build locally](#build-locally)
- [Image](#image)
- [Environment variables](#environment-variables)
- [Ports](#ports)
- [Usage](#usage)
  - [Docker Compose](#docker-compose)
  - [Command line](#command-line)
  - [Testing](#testing)
- [Upgrade](#upgrade)
- [Tor Control Port](#tor-control-port)
- [Contributing](#contributing)
- [License](#license)

## Features

- Support for diversity of proxy servers (`Socks5`, `HTTP`, `Shadowsocks` and more)
- Preinstalled the popular `Lyrebird`, `Meek`, and `Snowflake` transports
- Default use of Tor DNS resolver
- Multi-platform image

## Build locally

Build time can time up to 10 minutes, depending on your system.

```shell
git clone https://github.com/shahradelahi/docker-torproxy
cd docker-torproxy

# Build image and output to docker (default)
docker buildx bake

# Build multi-platform image
docker buildx bake image-all
```

## Image

| Registry                                                                                               | Image                           |
| ------------------------------------------------------------------------------------------------------ | ------------------------------- |
| [Docker Hub](https://hub.docker.com/r/shahradel/torproxy/)                                             | `shahradel/torproxy`            |
| [GitHub Container Registry](https://github.com/users/shahradelahi/packages/container/package/torproxy) | `ghcr.io/shahradelahi/torproxy` |

Following platforms for this image are available:

```
$ docker run --rm mplatform/mquery shahradel/torproxy:latest
Image: shahradel/torproxy:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/amd64
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
   - linux/386
   - linux/s390x
```

## Ports

This section depend on your configuration but for the most part, the default ports are:

- `1080`: `Socks5` proxy
- `8080`: `HTTP` proxy

## Environment variables

To configure the Tor config file you can mount the configs to `/etc/tor/torrc.d` directory or prefix the environment
variables with `TOR_`. For example, if you can set SocksPort option you have to add `TOR_SOCKS_PORT=1080` to the
environment variables.

| Option               | Description                                                        |
| -------------------- | ------------------------------------------------------------------ |
| `TOR_CONTROL_PASSWD` | Automatically will be hashed and used as password of control port. |
| `TOR_*`              | For configuring the Tor config file.                               |

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following
[docker compose template](docker-compose.yml), then run the container:

```bash
docker compose up -d
docker compose logs -f
```

### Command line

By default, the image is started with two password-less `socks5` and `http` proxies and image can be run by a minimal
command:

```bash
$ docker run -d --name torproxy \
  -p 1080:1080 -p 8080:8080 \
  shahradel/torproxy
```

To configure the proxy servers you can add flags to the command:

```bash
$ docker run -d --name torproxy \
  -p 1080:1080 -p 8080:8080 -p 8338:8338 \
  shahradel/torproxy \
  -L "http://:8080" \
  -L "socks5://<username>:<password>@:1080" \
  -L "ss://AES-256-CFB:<username>:<password>@:8338"
```

### Testing

```bash
# Socks5
curl -x socks5://localhost:1080 https://check.torproject.org/api/ip

# HTTP
curl -x http://localhost:8080 https://check.torproject.org/api/ip
```

## Upgrade

Recreate the container whenever I push an update:

```bash
docker compose pull
docker compose up -d
```

## Tor Control Port

By default, the control port is not exposed and for security reasons, it can be enabled by setting
the `TOR_CONTROL_PORT` and `TOR_HASHED_CONTROL_PASSWORD` environment variables.

```bash
$ docker run -d --name torproxy \
  -p 9060:9060 \
  -e TOR_CONTROL_PORT=9060 \
  -e TOR_CONTROL_PASSWD="super-secure-password" \
  shahradel/torproxy
```

Now tor control port is available on port `9060` and you can use tools such as [nyx](https://nyx.torproject.org/) to
monitor the tor instance.

```bash
$ docker exec -it torproxy nyx -i 9060
```

## Contributing

Want to contribute? Awesome! To show your support is to star the project, or to raise issues
on [GitHub](https://github.com/shahradelahi/docker-cfw-proxy).

Thanks again for your support, it is much appreciated! 🙏

## License

[GPL-3.0](/LICENSE) © [Shahrad Elahi](https://github.com/shahradelahi)
