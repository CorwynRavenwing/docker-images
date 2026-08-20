#!/bin/sh

set -e

# (1) Repoint sources.list to Archive and allow unauthenticated repos for EOL releases
if [ -f /etc/os-release ] && grep -qE 'stretch|jessie|wheezy|squeeze' /etc/os-release; then
    # Extract codename from VERSION_CODENAME, or fallback to parsing "8 (jessie)" / "9 (stretch)" from VERSION
    CODENAME=""

    # 1. Try VERSION_CODENAME in /etc/os-release
    if [ -f /etc/os-release ]; then
        CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' | head -n1)
    fi

    # 2. Fallback: Parse parenthesis from VERSION line in /etc/os-release
    if [ -z "$CODENAME" ] && [ -f /etc/os-release ]; then
        CODENAME=$(grep '^VERSION=' /etc/os-release 2>/dev/null | sed -n 's/.*(\(.*\)).*/\1/p' | head -n1)
    fi

    # 3. Fallback: Check /etc/debian_version
    if [ -z "$CODENAME" ] && [ -f /etc/debian_version ]; then
        VER=$(cat /etc/debian_version)
        case "$VER" in
            10*|buster*) CODENAME="buster" ;;
            9*|stretch*) CODENAME="stretch" ;;
            8*|jessie*)  CODENAME="jessie" ;;
            7*|wheezy*)  CODENAME="wheezy" ;;
            6*|squeeze*) CODENAME="squeeze" ;;
        esac
    fi

    # Hard fail if codename could not be identified
    if [ -z "$CODENAME" ]; then
        echo "ERROR: Unable to detect Debian codename from /etc/os-release or /etc/debian_version" >&2
        exit 1
    fi

    echo "Configuring archive repositories for Debian codename: ${CODENAME}"

    cat << EOF > /etc/apt/sources.list
deb http://archive.debian.org/debian/ ${CODENAME} main
deb http://archive.debian.org/debian-security/ ${CODENAME}/updates main
EOF

    # Disable release validation and allow unauthenticated packages globally
    cat << 'EOF' > /etc/apt/apt.conf.d/99archive
Acquire::Check-Valid-Until "false";
APT::Get::AllowUnauthenticated "true";
Acquire::AllowInsecureRepositories "true";
Acquire::AllowDowngradeToInsecureRepositories "true";
EOF
fi
