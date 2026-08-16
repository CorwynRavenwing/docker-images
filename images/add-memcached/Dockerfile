ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN set -e; \
    apt-get update \
 && apt-get install -y --no-install-recommends libmemcached-dev zlib1g-dev libssl-dev \
 && pecl install memcached || pecl install memcached-2.2.0 \
 && docker-php-ext-enable memcached \
 && rm -rf /var/lib/apt/lists/*

