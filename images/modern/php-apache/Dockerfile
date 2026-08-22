# php-apache/Dockerfile

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

# will accept three-part X.Y.Z versions,
# as well as two-part X.Y versions, which always reference the latest available
FROM php:${PHP_VERSION}-apache

COPY scripts/fix-debian-apt.sh /tmp/fix-debian-apt.sh
RUN sh /tmp/fix-debian-apt.sh && rm /tmp/fix-debian-apt.sh

# Enable standard Apache modules like mod_rewrite
RUN a2enmod rewrite

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Enable mod_rewrite and allow .htaccess overrides + FollowSymLinks in /var/www/html
RUN set -e; \
    a2enmod rewrite \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Document root defaults to /var/www/html
WORKDIR /var/www/html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=2 \
  CMD curl -f http://localhost/ || exit 1

CMD ["apache2-foreground"]
