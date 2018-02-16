#!/bin/bash

NGINX_DOWNLOAD_URL="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
NGINX_LUA_MODULE_DOWNLOAD_URL="https://github.com/openresty/lua-nginx-module/archive/v${LUA_VERSION}.tar.gz"
LUA_JIT_DOWNLOAD_URL=http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz
NGINX_DEVEL_KIT_DOWNLOAD_URL="https://github.com/simpl/ngx_devel_kit/archive/v${NGINX_DEVEL_KIT_VERSION}.tar.gz"

RUNTIME_DEPENDENCIES="libpcre3 libssl1.0.0 libxslt1.1 libgeoip1 vim iputils-ping libgd3"
BUILD_DEPENDENCIES="build-essential make wget libpcre3-dev zlib1g-dev libgd-dev libssl-dev libxslt-dev libgeoip-dev libgd-dev"

download_and_extract() {
  src=${1}
  dest=${2}
  tarball=$(basename ${src})

  if [ ! -f ${NGINX_SETUP_DIR}/sources/${tarball} ]; then
    echo "Downloading ${tarball}..."
    mkdir -p ${NGINX_SETUP_DIR}/sources/
    wget ${src} -O ${NGINX_SETUP_DIR}/sources/${tarball}
  fi

  echo "Extracting ${tarball}..."
  mkdir ${dest}
  tar -zxf ${NGINX_SETUP_DIR}/sources/${tarball} --strip=1 -C ${dest}
  rm -rf ${NGINX_SETUP_DIR}/sources/${tarball}
}

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ${RUNTIME_DEPENDENCIES} ${BUILD_DEPENDENCIES}


# download nginx
download_and_extract "${NGINX_DOWNLOAD_URL}" "${NGINX_SETUP_DIR}/nginx"
# download nginx dev
download_and_extract "${NGINX_DEVEL_KIT_DOWNLOAD_URL}" "${NGINX_SETUP_DIR}/nginx-devel-module"
# prepare lua module support
${WITH_LUA} && {
  #install LuaJIT
  download_and_extract "${LUA_JIT_DOWNLOAD_URL}" "${NGINX_SETUP_DIR}/luajit"
  cd "${NGINX_SETUP_DIR}/luajit" && make && make install
  download_and_extract "${NGINX_LUA_MODULE_DOWNLOAD_URL}" "${NGINX_SETUP_DIR}/nginx-lua-module"
  EXTRA_ARGS="${EXTRA_ARGS} --with-ld-opt='-Wl,-rpath,${LUAJIT_LIB}'  --add-dynamic-module=${NGINX_SETUP_DIR}/nginx-lua-module --add-dynamic-module=${NGINX_SETUP_DIR}/nginx-devel-module"

  mkdir -p /opt/openresty
  download_and_extract "https://github.com/openresty/lua-resty-redis/archive/v0.24.tar.gz" "/opt/openresty"
  download_and_extract "https://github.com/pintsized/lua-resty-redis-connector/archive/v0.03.tar.gz" "/opt/openresty"
}
cd ${NGINX_SETUP_DIR}/nginx

./configure \
  --prefix=/usr/share/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --sbin-path=/usr/sbin \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/var/run/nginx.pid \
  --with-pcre-jit \
  --with-ipv6 \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_auth_request_module \
  --with-http_addition_module \
  --with-http_dav_module \
  --with-http_geoip_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_image_filter_module \
  --with-http_v2_module \
  --with-http_sub_module \
  --with-http_xslt_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-threads \
 ${EXTRA_ARGS}

make -j$(nproc) && make install

apt-get purge -y --auto-remove ${BUILD_DEPENDENCIES}
rm -rf ${NGINX_SETUP_DIR}/{nginx,nginx-rtmp-module,ngx_pagespeed,libav}
rm -rf /var/lib/apt/lists/*