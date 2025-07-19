FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y \
    curl \
    build-essential \ 
    gcc-riscv64-unknown-elf

RUN mkdir /app

WORKDIR /workspace
