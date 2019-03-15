FROM rust:latest

EXPOSE 9002
WORKDIR /patches_server

COPY ./Cargo.toml /patches_server
COPY ./Cargo.lock /patches_server

RUN cargo install

COPY ./patches_server/src /patches_server/src
