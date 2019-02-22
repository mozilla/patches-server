all:
	@echo 'Available make targets:'
	@grep '^[^#[:space:]^\.PHONY.*].*:' Makefile

server:
	docker run -p 9002:9002 -t mozilla/patches-server-dev python patches_server/patches_server.py

docker-image:
	docker build -t mozilla/patches-server-dev:latest .

run-shell:
	docker run -it mozilla/patches-server-dev /bin/sh

run-python:
	docker run -it mozilla/patches-server-dev python

run-pytest:
	docker run -t mozilla/patches-server-dev pytest