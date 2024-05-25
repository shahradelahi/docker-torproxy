# TorProxy

A latest version of Tor for with tools for creating a proxy server.

## Usage

By default, a `Socks5` and `HTTP` proxy server with no authentication will be created on port `1080` and `8080`
respectively.

```bash
docker run --rm -p 1080:1080 -p 8080:8080 \
  litehex/torproxy
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
  litehex/torproxy -L "socks5://<username>:<password>@:1080"
```

##### Configure Tor to use exit nodes in specified countries

```bash
docker run --rm \
  -p 1080:1080 \
  -e TOR_EXIT_NODES="{us},{ca},{gb}" \
  -e TOR_STRICT_NODES="1" \
  litehex/torproxy
```

##### Accessing the Tor control port

By default, the control port is not exposed and for security reasons, it can be enabled by setting
the `TOR_CONTROL_PORT` and `TOR_HASHED_CONTROL_PASSWORD` environment variables.

The container provides a feature for automatically generating a hashed password for the control port, by setting
the `TOR_CONTROL_PASSWD` environment variable.

```bash
docker run --rm --name torproxy \
  -p 9060:9060 \
  -e TOR_CONTROL_PORT=9060 \
  -e TOR_CONTROL_PASSWD="super-secure-password" \
  litehex/torproxy
```

Now tor control port is available on port `9060` and you can use tools such as [nyx](https://nyx.torproject.org/) to
monitor the tor instance.

```bash
docker exec -it torproxy nyx -i 9060
```

## Reporting

If you have any questions, bug reports, and feature requests, please create an issue
on [GitHub](https://github.com/shahradelahi/docker-torproxy/issues).

### License

This project is licensed under the GPLv3 License - see the [LICENSE](LICENSE) file for details
