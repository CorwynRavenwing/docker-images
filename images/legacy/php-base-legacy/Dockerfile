# php-base-legacy/Dockerfile

FROM debian:jessie-slim

# 1. Point archived Debian Jessie repos to archive.debian.org
COPY scripts/fix-debian-apt.sh /tmp/fix-debian-apt.sh
RUN sh /tmp/fix-debian-apt.sh && rm /tmp/fix-debian-apt.sh

ENV PHP_INI_SCAN_DIR=/usr/local/etc/php/conf.d
RUN mkdir -p /usr/local/etc/php/conf.d

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

# 4. Ensure docker-php-ext-* scripts exist
COPY scripts/docker-php-ext-configure /usr/local/bin/docker-php-ext-configure
COPY scripts/docker-php-ext-enable /usr/local/bin/docker-php-ext-enable
COPY scripts/docker-php-ext-install /usr/local/bin/docker-php-ext-install
RUN chmod +x /usr/local/bin/docker-php-ext-*

# --- CACHE BOUNDARY ---
# Everything above this line is 100% identical for all 5.x versions and cached ONCE.

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

# A. grab cached version of php source tarball
COPY ./downloads/php-${PHP_VERSION}.tar.bz2 /usr/src/php.tar.bz2
# ... and we now keep this file when we're done

# B. Configure, Compile, and Install all SAPIs (CLI, FPM, Apache mod_php)
# Note: FPM is unconditionally disabled
# Note: OpenSSL is unconditionally disabled
# Stub out ext/openssl C files so ./configure completely skips building it
# Stub out ext/dom C files to bypass libxml2 2.9+ opaque struct errors
# Stub out ext/simplexml C files to bypass libxml2 2.9+ opaque buffer errors
# Explicitly disable DOM extension in configure
# Explicitly disable SimpleXML extension in configure
RUN mkdir -p /usr/src/php \
 && tar -xjf /usr/src/php.tar.bz2 -C /usr/src/php --strip-components=1 \
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

# Healthcheck for PHP CLI/FPM processes
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD php -v || exit 1

CMD ["php", "-a"]
