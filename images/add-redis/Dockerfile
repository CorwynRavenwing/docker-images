# images/add-redis/Dockerfile

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

COPY scripts/install-pecl-ext.sh /tmp/install-pecl-ext.sh
RUN sh /tmp/install-pecl-ext.sh redis && rm /tmp/install-pecl-ext.sh
