#!/bin/sh
set -e

EXT_NAME="$1"
PHP_VER=$(php -r 'echo PHP_VERSION;')
PHP_MAJOR=$(echo "$PHP_VER" | cut -d. -f1)
PHP_MINOR=$(echo "$PHP_VER" | cut -d. -f2)

get_version() {
    case "$EXT_NAME" in
        imagick)
            if [ "$PHP_MAJOR" -ge 7 ]; then echo "imagick";
            else echo "imagick-3.4.4"; fi
            ;;
        memcached)
            if [ "$PHP_MAJOR" -ge 7 ]; then echo "memcached";
            else echo "memcached-2.2.0"; fi
            ;;
        redis)
            if [ "$PHP_MAJOR" -ge 7 ]; then echo "redis";
            else echo "redis-4.3.0"; fi
            ;;
        xdebug)
            if [ "$PHP_MAJOR" -ge 8 ]; then echo "xdebug";
            elif [ "$PHP_MAJOR" -eq 7 ]; then echo "xdebug-2.9.8";
            elif [ "$PHP_MAJOR" -eq 5 ] && [ "$PHP_MINOR" -ge 4 ]; then echo "xdebug-2.5.5";
            else echo "xdebug-2.2.7"; fi
            ;;
        *)
            echo "$EXT_NAME"
            ;;
    esac
}

TARGET_PKG=$(get_version)
echo "=== Installing PECL package: ${TARGET_PKG} for PHP ${PHP_VER} ==="

pecl channel-update pecl.php.net || true
pecl install "$TARGET_PKG"
docker-php-ext-enable "$EXT_NAME"

# memcached might need echo "" | pecl install $X because of prompts to enable options
