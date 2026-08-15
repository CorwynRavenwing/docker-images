# php-legacy-apache/Dockerfile

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

FROM php-base-legacy:${PHP_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends apache2 \
    && rm -rf /var/lib/apt/lists/*

# 1. Create the Debian load file for php5
# 2. Enable the php5 module
# 3. Switch Apache from threaded MPM (event/worker) to prefork (required for NTS PHP)
# 4. Tell Apache to execute .php files using the loaded PHP module
# 5. Suppress healthcheck (curl) requests from Apache access logs
RUN set -e; \
    echo "LoadModule php5_module /usr/lib/apache2/modules/libphp5.so" > /etc/apache2/mods-available/php5.load \
    && a2dismod mpm_event mpm_worker || true \
    && a2enmod mpm_prefork php5 \
    && echo '<FilesMatch \.php$>\n\tSetHandler application/x-httpd-php\n</FilesMatch>\nDirectoryIndex index.php index.html' > /etc/apache2/conf-available/php-handler.conf \
    && a2enconf php-handler \
    && echo 'SetEnvIf User-Agent "^curl" dontlog' \
        >> /etc/apache2/apache2.conf \
    && sed -i 's/CustomLog \(.*\) combined/CustomLog \1 combined env=!dontlog/' \
        /etc/apache2/sites-available/000-default.conf

# Redirect Apache access and error logs to container stdout/stderr
RUN set -e; \
    ln -sf /dev/stdout /var/log/apache2/access.log \
 && ln -sf /dev/stderr /var/log/apache2/error.log

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["apache2ctl", "-D", "FOREGROUND"]

