
DOCKER_FILE := docker/docker-compose.dev.yml
TOKEN_PATH ?= $(HOME)/.token
OAUTH_TOKEN ?= `cat ${TOKEN_PATH}`
DEV_DOCKER_FILE := docker/docker-compose.dev.yml

.PHONY: deps
deps:
	mix deps.get

.PHONY: deps-update
deps-update:
	mix deps.update --all

.PHONY: build
build:
	mix compile

.PHONY: lint
lint:
	mix credo --strict

.PHONY: test
test: lint
	mkdir -p _build/reports
	mix test --formatter JUnitFormatter --formatter ExUnit.CLIFormatter --cover
	-cp coverage.xml _build/reports

.PHONY: dialyzer
dialyzer:
	mix dialyzer

.PHONY: build-dev-docker
build-dev-docker:
	docker build --build-arg OAUTH_TOKEN="${OAUTH_TOKEN}" -t rakv_client -f docker/dev.Dockerfile .



