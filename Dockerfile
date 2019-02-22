FROM python:3.7.2-alpine3.8

WORKDIR /patches_server
ADD ./patches_server /patches_server

RUN pip install -r /patches_server/requirements_dev.txt