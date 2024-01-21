FROM debian:latest

RUN useradd -ms /bin/bash victim

USER victim

WORKDIR /home/victim

ADD network.exe .

USER root
RUN chmod +x /home/victim/network.exe
RUN apt update && apt upgrade -y && apt install -y iputils-ping iproute2
USER victim

RUN ./network.exe