# php-base-legacy/Dockerfile

FROM debian:jessie-slim

# 1. Point archived Debian Jessie repos to archive.debian.org
RUN echo "deb http://archive.debian.org/debian/ jessie main" \
    > /etc/apt/sources.list \
 && echo "deb http://archive.debian.org/debian-security/ jessie/updates main" \
    >> /etc/apt/sources.list \
 && echo 'Acquire::Check-Valid-Until "false";' \
    > /etc/apt/apt.conf.d/99no-check-valid-until

# 2. Install build tools, Apache server & dev headers, and core libraries
RUN apt-get update \
 && apt-get install \
        -y \
        --force-yes \
        --no-install-recommends \
    apache2 \
    apache2-dev \
    bison \
    build-essential \
    bzip2 \
    ca-certificates \
    curl \
    dpkg-dev \
    flex \
    libssl-dev \
    libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

# 3. Create multiarch symlinks so legacy ./configure finds 64-bit libraries
RUN ARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH) \
 && ln -s /usr/lib/${ARCH}/libssl.so /usr/lib/ 2>/dev/null || true \
 && ln -s /usr/lib/${ARCH}/libcrypto.so /usr/lib/ 2>/dev/null || true \
 && ln -s /usr/lib/${ARCH}/libxml2.so /usr/lib/ 2>/dev/null || true

# --- CACHE BOUNDARY ---
# Everything above this line is 100% identical for all 5.x versions and cached ONCE.

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

# 4. grab cached version of php source tarball
COPY ./downloads/php-${PHP_VERSION}.tar.bz2 /tmp/php.tar.bz2

# 5. Configure, Compile, and Install all SAPIs (CLI, FPM, Apache mod_php)
# Note: FPM is unconditionally disabled
# Note: OpenSSL is unconditionally disabled
# Stub out ext/openssl C files so ./configure completely skips building it
# Stub out ext/dom C files to bypass libxml2 2.9+ opaque struct errors
# Stub out ext/simplexml C files to bypass libxml2 2.9+ opaque buffer errors
# Explicitly disable DOM extension in configure
# Explicitly disable SimpleXML extension in configure
RUN mkdir -p /usr/src/php \
 && tar -xjf /tmp/php.tar.bz2 -C /usr/src/php --strip-components=1 \
 && rm /tmp/php.tar.bz2 \
 && cd /usr/src/php \
 && find ext/openssl -name "*.c" -exec cp /dev/null {} \; \
 && find ext/dom -name "*.c" -exec cp /dev/null {} \; \
 && find ext/simplexml -name "*.c" -exec cp /dev/null {} \; \
 && export CFLAGS="-O2 -w" \
 && export CPPFLAGS="-Dunixd_config=ap_unixd_config -Dap_get_server_version=ap_get_server_banner" \
 && ./configure \
        --prefix=/usr/local \
        --with-config-file-path=/usr/local/etc \
        --with-apxs2=/usr/bin/apxs \
        --without-openssl \
        --disable-dom \
        --disable-simplexml \
        --enable-mbstring \
        --with-libxml-dir=/usr \
        --without-pear \
 && make -j"$(nproc)" \
 && make install \
 && rm -rf /usr/src/php

CMD ["php", "-a"]
