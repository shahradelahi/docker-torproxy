IMAGE=litehex/torproxy
TAG=dev

DOCKER_BUILD=docker buildx build

build:
	$(DOCKER_BUILD) -t $(IMAGE):$(TAG) .

run:
	docker rm -f torproxy || true
	docker run -d -p 9050:9050 --name torproxy $(IMAGE):$(TAG) -L auto://:9050

logs:
	docker logs -f --tail 50 torproxy

test:
	curl -x socks5://localhost:9050 https://check.torproject.org/api/ip