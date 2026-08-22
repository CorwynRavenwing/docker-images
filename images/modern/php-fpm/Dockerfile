# php-fpm/Dockerfile

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

# will accept three-part X.Y.Z versions,
# as well as two-part X.Y versions, which always reference the latest available
FROM php:${PHP_VERSION}-fpm

COPY scripts/fix-debian-apt.sh /tmp/fix-debian-apt.sh
RUN sh /tmp/fix-debian-apt.sh && rm /tmp/fix-debian-apt.sh

# Ensure FPM listens on 0.0.0.0:9000 across all official PHP versions
# (Official images use zz-docker.conf to set the default listen port)
RUN if [ -f /usr/local/etc/php-fpm.d/zz-docker.conf ]; then \
        sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.d/zz-docker.conf; \
    fi; \
    if [ -f /usr/local/etc/php-fpm.d/www.conf ]; then \
        sed -i 's/^listen = .*/listen = 0.0.0.0:9000/' /usr/local/etc/php-fpm.d/www.conf; \
    fi

EXPOSE 9000

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=2 \
  CMD pidof php-fpm || exit 1

CMD ["php-fpm"]
