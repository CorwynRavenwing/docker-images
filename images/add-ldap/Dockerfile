# images/add-ldap/Dockerfile

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN set -e; \
    apt-get update \
 && apt-get install -y --no-install-recommends \
        libldap2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -e; \
    if command -v docker-php-ext-install >/dev/null 2>&1; then \
        docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ ; \
        docker-php-ext-install -j$(nproc) ldap ; \
    fi

