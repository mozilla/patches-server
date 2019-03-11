FROM python:3.7.2-alpine3.8

EXPOSE 9002
WORKDIR /patches_server

COPY ./patches_server/requirements_dev.txt /patches_server

RUN pip install -r /patches_server/requirements_dev.txt

ENV CONFIG_FILE /patches_server/patches_server/config/default.py

COPY ./patches_server /patches_server
