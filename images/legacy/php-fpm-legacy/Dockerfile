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

# 4. Use php-fpm for 5.3-5.5, or spawn-fcgi with php-cgi for 5.0-5.2
CMD ["sh", "-c", "if [ -f /usr/local/sbin/php-fpm ]; then exec php-fpm -F; else exec spawn-fcgi -n -a 0.0.0.0 -p 9000 -u www-data -g www-data -f /usr/local/bin/php-cgi; fi"]
