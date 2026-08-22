# php-cli/Dockerfile

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

# will accept three-part X.Y.Z versions,
# as well as two-part X.Y versions, which always reference the latest available
FROM php:${PHP_VERSION}-cli

COPY scripts/fix-debian-apt.sh /tmp/fix-debian-apt.sh
RUN sh /tmp/fix-debian-apt.sh && rm /tmp/fix-debian-apt.sh

WORKDIR /app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD php -v || exit 1

CMD ["php", "-v"]
