# php-apache/Dockerfile

ARG PHP_VERSION=REQUIRED_BUILD_ARG_MISSING

# will accept three-part X.Y.Z versions,
# as well as two-part X.Y versions, which always reference the latest available
FROM php:${PHP_VERSION}-apache

# Enable standard Apache modules like mod_rewrite
RUN a2enmod rewrite

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Document root defaults to /var/www/html
WORKDIR /var/www/html

EXPOSE 80

HEALTHCHECK --interval=1s --timeout=2s --start-period=1s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["apache2-foreground"]
