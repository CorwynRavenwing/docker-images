# php-fpm-legacy/Dockerfile

# First ARG scoped only for FROM
ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING
FROM php-base-legacy:${PHP_VERSION}

# Second ARG line required so RUN instructions below can access PHP_VERSION
ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

# 1. Install spawn-fcgi with --force-yes (needed for PHP 5.0-5.2)
RUN apt-get update && apt-get install -y --force-yes --no-install-recommends \
    spawn-fcgi \
 && rm -rf /var/lib/apt/lists/*

# Copy the 5.0 patch script into the build context
COPY scripts/patch-legacy-mysqli.sh /usr/local/bin/

# 2. grab cached version of php source tarball
COPY ./downloads/php-${PHP_VERSION}.tar.bz2 /tmp/php.tar.bz2

# 3. compile FPM (5.3-5.5) or FastCGI (5.0-5.2)
RUN mkdir -p /usr/src/php \
 && tar -xjf /tmp/php.tar.bz2 -C /usr/src/php --strip-components=1 \
 && rm /tmp/php.tar.bz2 \
 && cd /usr/src/php \
 && find ext/openssl -name "*.c" -exec cp /dev/null {} \; \
 && find ext/dom -name "*.c" -exec cp /dev/null {} \; \
 && find ext/simplexml -name "*.c" -exec cp /dev/null {} \; \
 \
 # Run the legacy mysqli patch script for versions 5.0-5.2 \
 && case "${PHP_VERSION}" in \
        5.0*|5.1*|5.2*) patch-legacy-mysqli.sh ;; \
    esac \
 \
 && export CFLAGS="-O2 -w" \
 && CONFIGURE_SAPI=$(case "${PHP_VERSION}" in \
        "5.0"|"5.1"|"5.2") echo "--enable-fastcgi" ;; \
        *) echo "--enable-fpm" ;; \
    esac) \
 && ./configure \
        --prefix=/usr/local \
        --with-config-file-path=/usr/local/etc \
        ${CONFIGURE_SAPI} \
        --without-openssl \
        --disable-dom \
        --disable-simplexml \
        --enable-mbstring \
        --with-libxml-dir=/usr \
        --without-pear \
        --with-mysqli=/usr/bin/mysql_config \
        --with-mysql=/usr \
 && make -j"$(nproc)" \
 && make install \
 && if [ ! -f /usr/local/bin/php-cgi ] && [ -f /usr/local/bin/php ]; then \
        ln -sf /usr/local/bin/php /usr/local/bin/php-cgi; \
    fi \
 && rm -rf /usr/src/php

# 3. Create minimal php-fpm.conf if building 5.3-5.5
RUN if [ -f /usr/local/sbin/php-fpm ]; then \
        echo '[global]' > /usr/local/etc/php-fpm.conf \
        && echo 'daemonize = no' >> /usr/local/etc/php-fpm.conf \
        && echo '[www]' >> /usr/local/etc/php-fpm.conf \
        && echo 'user = www-data' >> /usr/local/etc/php-fpm.conf \
        && echo 'group = www-data' >> /usr/local/etc/php-fpm.conf \
        && echo 'listen = 0.0.0.0:9000' >> /usr/local/etc/php-fpm.conf \
        && echo 'pm = dynamic' >> /usr/local/etc/php-fpm.conf \
        && echo 'pm.max_children = 5' >> /usr/local/etc/php-fpm.conf \
        && echo 'pm.start_servers = 2' >> /usr/local/etc/php-fpm.conf \
        && echo 'pm.min_spare_servers = 1' >> /usr/local/etc/php-fpm.conf \
        && echo 'pm.max_spare_servers = 3' >> /usr/local/etc/php-fpm.conf ; \
    fi

EXPOSE 9000

HEALTHCHECK --interval=1s --timeout=2s --start-period=1s --retries=3 \
  CMD nc -z 127.0.0.1 9000 || exit 1

# Copy the unified entrypoint script into the container
COPY scripts/docker-fpm-5-entrypoint.sh /usr/local/bin/docker-fpm-5-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-fpm-5-entrypoint.sh

# Use the script as the container entrypoint/command
CMD ["docker-fpm-5-entrypoint.sh"]
