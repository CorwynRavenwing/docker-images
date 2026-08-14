# images/add-tsql/Dockerfile

# Declare ARG before FROM so it can be used in the FROM instruction
# no default, so the system will fail quickly if used improperly
ARG BASE_IMAGE

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
# (Modern PHP images with docker-php-ext-enable)
RUN if command -v docker-php-ext-enable >/dev/null 2>&1; then \
        docker-php-ext-configure pdo_dblib --with-libdir=lib/x86_64-linux-gnu/ ; \
        docker-php-ext-install -j$(nproc) pdo_dblib ; \
    fi