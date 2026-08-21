# images/single/pgsql/Dockerfile

FROM postgres:15-alpine

# Set default development credentials
ENV POSTGRES_USER=app_user \
    POSTGRES_PASSWORD=app_secret \
    POSTGRES_DB=app_db

# Expose default PostgreSQL port
EXPOSE 5432

# Custom startup configs or init scripts can be copied here if needed
# COPY ./config/init.sql /docker-entrypoint-initdb.d/
