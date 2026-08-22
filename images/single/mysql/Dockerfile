# images/single/mysql/Dockerfile

FROM mariadb:10.11

# Set default development credentials
ENV MYSQL_ROOT_PASSWORD=root_secret \
    MYSQL_DATABASE=app_db \
    MYSQL_USER=app_user \
    MYSQL_PASSWORD=app_secret

HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=3 \
  CMD mariadb-admin ping -h 127.0.0.1 -u$$MYSQL_USER -p$$MYSQL_PASSWORD || exit 1

# Expose default MySQL port
EXPOSE 3306
