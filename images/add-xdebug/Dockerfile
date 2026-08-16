# images/add-xdebug/Dockerfile

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

RUN set -e; \
    if command -v pecl >/dev/null 2>&1; then \
        pecl install xdebug && docker-php-ext-enable xdebug ; \
    fi
