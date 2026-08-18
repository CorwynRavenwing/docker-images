# images/add-pgsql/Dockerfile

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

RUN set -e; \
    apt-get update \
 && apt-get install -y --no-install-recommends libpq-dev \
 && docker-php-ext-install -j$(nproc) pgsql pdo_pgsql \
 && rm -rf /var/lib/apt/lists/*

