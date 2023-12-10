# TorProxy

Just a latest version of Tor and extra tools to run it as a proxy server.

## Usage

By default, a `Socks5` and `HTTP` proxy server with no authentication will be created on port `1080` and `8080`
respectively.

```bash
docker run --rm \
  -p 1080:1080 \
  -p 8080:8080 \
  litehex/torproxy:latest
```

Testing the proxy server.

```bash
# Socks5
curl -x socks5://localhost:1080 https://www.cloudflare.com/cdn-cgi/trace/

# HTTP
curl -x http://localhost:8080 https://check.torproject.org/api/ip
```

## Examples

##### Create a Socks5 proxy server with authentication

```bash
docker run --rm \
  -p 1080:1080 \
  litehex/torproxy:latest -L "socks5://<username>:<password>@:1080"
```

##### Configure Tor to use a specific exit node

```bash
docker run --rm \
  -p 1080:1080 \
  -e TOR_EXIT_NODE=ru \
  litehex/torproxy:latest
```

##### Accessing the Tor control port

By default, the control port is not exposed and for security reasons,
it can be enabled by setting the `TOR_CONTROL_PORT` and `TOR_CONTROL_PASSWD` environment variables.

First, you need to set a password for the control port.

```bash
docker run --rm \
  -p 9051:9051 \
  -e TOR_CONTROL_PORT=9051 \
  -e TOR_CONTROL_PASSWD="super-secure-password" \
  litehex/torproxy:latest
```

Now tor control port is available on port `9051`
and you can use tools such as [nyx](https://nyx.torproject.org/) to monitor the tor instance.

```bash
nyx -i 127.0.0.1:9051
```

### License

This project is licensed under the GPLv3 License - see the [LICENSE](LICENSE) file for details