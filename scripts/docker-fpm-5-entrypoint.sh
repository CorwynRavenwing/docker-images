#!/usr/bin/env bash
set -Eeuo pipefail

# If the native php-fpm binary exists (PHP 5.3+), run it.
# Otherwise, fall back to running php-cgi in standalone FastCGI daemon mode (PHP 5.0-5.2)

# Check if native php-fpm binary exists (PHP 5.3+)
if [ -f /usr/local/sbin/php-fpm ]; then
    echo "FPM: version 5.3+ running php-fpm"
    exec php-fpm -F
else
    # Fallback for PHP 5.0 - 5.2 using php-cgi daemon mode via spawn-fcgi
    echo "FPM: version 5.2- running php-cgi"
    exec spawn-fcgi -n -a 0.0.0.0 -p 9000 -u www-data -g www-data -f /usr/local/bin/php-cgi
fi
