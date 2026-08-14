# images/add-redis/Dockerfile

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN set -e; \
    if command -v pecl >/dev/null 2>&1; then \
        pecl install redis && docker-php-ext-enable redis ; \
    fi

