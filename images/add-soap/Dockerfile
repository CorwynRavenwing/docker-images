# images/add-soap/Dockerfile

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

RUN set -e; \
    apt-get update \
 && apt-get install -y --no-install-recommends libxml2-dev \
 && docker-php-ext-install -j$(nproc) soap \
 && rm -rf /var/lib/apt/lists/*

