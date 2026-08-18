# images/add-memcached/Dockerfile

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

RUN set -e; \
    apt-get update \
 && apt-get install -y --no-install-recommends libmemcached-dev zlib1g-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*

COPY scripts/install-pecl-ext.sh /tmp/install-pecl-ext.sh
RUN sh /tmp/install-pecl-ext.sh memcached && rm /tmp/install-pecl-ext.sh
