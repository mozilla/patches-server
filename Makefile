all:
	@echo 'Available make targets:'
	@grep '^[^#[:space:]^\.PHONY.*].*:' Makefile

docker-image:
	docker build -t mozilla/patches-server-dev:latest .

run-shell:
	docker run -it mozilla/patches-server-dev /bin/sh

run-python:
	docker run -it mozilla/patches-server-dev python

run-unit-tests: docker-image
	docker run -t mozilla/patches-server-dev pytest

run-all-tests: docker-image
	docker-compose up -d
	docker run -t mozilla/patches-server-dev pytest
	docker-compose stop

run-server: docker-image
	docker-compose up