# images/add-tsql/Dockerfile

# Declare ARG before FROM so it can be used in the FROM instruction
# scratch === an invalid default, so the system will fail quickly if used improperly
ARG BASE_IMAGE=scratch

FROM ${BASE_IMAGE}

# Add sqlcmd PATH permanently to the container environment
ENV PATH="${PATH}:/opt/mssql-tools18/bin:/usr/bin"

RUN set -e; \
    apt-get update && apt-get install -y --no-install-recommends \
        freetds-bin \
        freetds-dev \
        tdsodbc \
        freetds-common \
    && rm -rf /var/lib/apt/lists/*

# Configure FreeTDS / pdo_dblib extension where applicable
# (Modern PHP images with docker-php-ext-install)
RUN if command -v docker-php-ext-install >/dev/null 2>&1; then \
        docker-php-ext-configure pdo_dblib --with-libdir=lib/x86_64-linux-gnu/ ; \
        docker-php-ext-install -j$(nproc) pdo_dblib ; \
    else \
        PHP_VER=$(php -r 'echo PHP_VERSION;') ; \
        tar -xjf downloads/php-${PHP_VER}.tar.bz2 -C /tmp/ ; \
        cd /tmp/php-${PHP_VER}/ext/pdo_dblib ; \
        phpize ; \
        ./configure --with-pdo-dblib=/usr --with-libdir=lib/x86_64-linux-gnu/ ; \
        make -j$(nproc) && make install ; \
        docker-php-ext-enable pdo_dblib || true ; \
        rm -rf /tmp/php-${PHP_VER} ; \
    fi
