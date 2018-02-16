FROM ubuntu:16.04
LABEL maintainer "Vitalii Samotaiev <vsamotaev@glash.io>"

ENV DEBIAN_FRONTEND noninteractive

ARG NGINX_VERSION
ENV NGINX_VERSION=${NGINX_VERSION:-1.13.8} \
    LUA_VERSION=0.10.11 \
    NGINX_DEVEL_KIT_VERSION=0.3.0 \
    LUAJIT_VERSION=2.0.5 \
    NGINX_USER=nginx \
    NGINX_LOG_DIR=/var/log/nginx \
    NGINX_TEMP_DIR=/var/lib/nginx \
    NGINX_SETUP_DIR=/var/cache/nginx \
    LUAJIT_LIB=/usr/local/lib \
    LUAJIT_INC=/usr/local/include/luajit-2.0

ARG WITH_LUA=true

COPY ./setup.sh ${NGINX_SETUP_DIR}/setup.sh

RUN bash ${NGINX_SETUP_DIR}/setup.sh

RUN mkdir -p /mnt/data /etc/nginx/lua /etc/nginx/ssl
VOLUME ["/mnt/data", "/etc/nginx/conf.d", "/etc/nginx/ssl"]

ADD ./etc/nginx/conf.d/* /etc/nginx/conf.d/
ADD ./etc/nginx/nginx.conf /etc/nginx

EXPOSE 80 443
CMD nginx -g 'daemon off;'