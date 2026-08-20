#!/bin/sh
set -e

EXT_NAME="$1"
if [ -z "$EXT_NAME" ]; then
    echo "Usage: $0 <extension-name>" >&2
    exit 1
fi
PHP_VER=$(php -r 'echo PHP_VERSION;')
PHP_MAJOR_MINOR=$(echo "$PHP_VER" | cut -d. -f1,2)

# Pin extension versions based on PHP compatibility
EXT_VERSION=""
case "$EXT_NAME" in
    imagick)
        case "$PHP_MAJOR_MINOR" in
            5.3|5.4|5.5|5.6) EXT_VERSION="3.4.4" ;;
            7.0|7.1|7.2|7.3|7.4) EXT_VERSION="3.5.1" ;;
        esac
        ;;
    memcached)
        case "$PHP_MAJOR_MINOR" in
            5.*) EXT_VERSION="2.2.0" ;;
            7.*) EXT_VERSION="3.1.5" ;;
        esac
        ;;
    redis)
        case "$PHP_MAJOR_MINOR" in
            5.*) EXT_VERSION="4.3.0" ;;
            7.*) EXT_VERSION="5.3.7" ;;
        esac
        ;;
    xdebug)
        case "$PHP_MAJOR_MINOR" in
            5.3) EXT_VERSION="2.2.7" ;;
            5.4|5.5|5.6) EXT_VERSION="2.5.5" ;;
            7.*) EXT_VERSION="2.9.8" ;;
        esac
        ;;
    *)
        # Unpinned extensions will default to downloading the latest release
        ;;
esac

PKG_SPEC="${EXT_NAME}"
[ -n "$EXT_VERSION" ] && PKG_SPEC="${EXT_NAME}-${EXT_VERSION}"
echo "=== Installing PECL package: ${TARGET_PKG} for PHP ${PHP_VER} ==="

# 1. Try standard 'pecl install' if the binary exists
if command -v pecl >/dev/null 2>&1; then
    pecl channel-update pecl.php.net || true
    if pecl install "$PKG_SPEC"; then
        docker-php-ext-enable "$EXT_NAME" || true
        echo "Successfully installed ${PKG_SPEC} via PECL"
        exit 0
    fi
    echo "WARNING: 'pecl install' failed. Attempting direct tarball compile via phpize..."
fi

# 2. Fallback: Download tarball directly and compile via phpize
echo "Building ${PKG_SPEC} directly from source tarball..."

# Ensure build prerequisites (autoconf, make, gcc) exist for phpize
if ! command -v autoconf >/dev/null 2>&1; then
    echo "autoconf not found; installing build prerequisites..."
    apt-get update && apt-get install -y --no-install-recommends autoconf build-essential
fi

TMP_DIR="/tmp/build-${EXT_NAME}"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# Determine archive name and fetch URL
TARBALL="${PKG_SPEC}.tgz"
FETCH_URL="https://pecl.php.net/get/${TARBALL}"

if command -v curl >/dev/null 2>&1; then
    curl -fsSL -k "$FETCH_URL" -o "$TARBALL"
elif command -v wget >/dev/null 2>&1; then
    wget --no-check-certificate -q "$FETCH_URL" -O "$TARBALL"
else
    echo "ERROR: Neither curl nor wget available to download ${FETCH_URL}" >&2
    exit 1
fi

tar -xzf "$TARBALL"
cd "${PKG_SPEC}" || cd "${EXT_NAME}-*"

phpize
./configure
make -j"$(nproc 2>/dev/null || echo 2)"
make install

docker-php-ext-enable "$EXT_NAME" || true

# Cleanup
cd /
rm -rf "$TMP_DIR"

echo "Successfully built and enabled ${PKG_SPEC}"

# memcached might need echo "" | pecl install $X because of prompts to enable options
