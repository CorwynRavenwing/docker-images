# images/add-imagick/Dockerfile

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

RUN set -e; \
    apt-get update \
 && apt-get install -y --no-install-recommends \
        imagemagick \
        libmagickwand-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -e; \
    if command -v pecl >/dev/null 2>&1; then \
        pecl install imagick && docker-php-ext-enable imagick ; \
    fi

