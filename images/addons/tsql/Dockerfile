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

RUN docker-php-ext-configure pdo_dblib --with-libdir=lib/x86_64-linux-gnu/ \
 && docker-php-ext-install -j$(nproc) pdo_dblib

