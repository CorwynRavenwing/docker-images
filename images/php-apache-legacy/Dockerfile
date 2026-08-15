# php-legacy-apache/Dockerfile

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

FROM php-base-legacy:${PHP_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends apache2 \
    && rm -rf /var/lib/apt/lists/*

# 1. Switch Apache from threaded MPM (event/worker) to prefork (required for NTS PHP)
# 2. Tell Apache to execute .php files using the loaded PHP module
RUN a2dismod mpm_event mpm_worker || true \
 && a2enmod mpm_prefork \
 && echo '<FilesMatch \.php$>\n\tSetHandler application/x-httpd-php\n</FilesMatch>\nDirectoryIndex index.php index.html' > /etc/apache2/conf-available/php-handler.conf \
 && a2enconf php-handler

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["apache2ctl", "-D", "FOREGROUND"]

