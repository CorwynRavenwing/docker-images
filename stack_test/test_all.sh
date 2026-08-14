#!/usr/bin/env bash
# set -e

# stack_test/test_all.sh

# Default to all 18 versions if no arguments are passed on the command line
if [ $# -gt 0 ]; then
    VERSIONS=("$@")
else
    # Version matrix matching your Makefile
    VERSIONS=(
        "5.0" "5.1" "5.2" "5.3" "5.4" "5.5" "5.6"
        "7.0" "7.1" "7.2" "7.3" "7.4"
        "8.0" "8.1" "8.2" "8.3" "8.4" "8.5"
    )
fi

PASSED_NGINX=0
FAILED_NGINX=0
PASSED_APACHE=0
FAILED_APACHE=0

test_version() {
    local ver="$1"
    printf "Testing PHP %-4s => " "$ver"

    # Clean teardown to force Nginx to re-resolve container IPs on fresh boot
    docker compose down --remove-orphans -v >/dev/null 2>&1
    sleep 0.5
    # Spin up Nginx + FPM and Apache for this specific PHP version
    PHP_VERSION="$ver" docker compose up -d --wait >/dev/null 2>&1

    # Check Nginx + PHP-FPM / CGI endpoint
    local nginx_out=""
    local nginx_status=""
    # Poll Nginx endpoint for up to 5 seconds to account for FPM startup time
    for i in {1..10}; do
        nginx_out=$(curl -s --max-time 1 http://localhost:8080 | tr '\n' ' ')
        if [[ "$nginx_out" =~ "fpm-fcgi" || "$nginx_out" =~ "cgi-fcgi" ]]; then
            break
        fi
        sleep 0.5
    done
    if [[ "$nginx_out" =~ "fpm-fcgi" || "$nginx_out" =~ "cgi-fcgi" ]]; then
        nginx_status="✓ Nginx (FPM/CGI) "
        ((PASSED_NGINX++))
    else
        local http_code
        # Extract HTTP status or raw response snippet for diagnosis
        http_code=$(echo "$NGINX_OUT" | grep -oE "HTTP/[1.2]+ [0-9]+" | awk '{print $2}')
        if [ -z "$http_code" ]; then
            http_code="NO_CONN"
        fi
        nginx_status="✗ Nginx ($http_code)"
        ((FAILED_NGINX++))
    fi

    # Check Apache Module
    local apache_out=""
    local apache_status=""
    apache_out=$(curl -s http://localhost:8081 | tr '\n' ' ')
    if [[ "$apache_out" =~ "apache2handler" ]]; then
        ((PASSED_APACHE++))
        apache_status="✓ Apache           "
    else
        local apache_code
        apache_code=$(echo "$apache_out" | grep -oE "HTTP/[1.2]+ [0-9]+" | awk '{print $2}')
        if [ -z "$apache_code" ]; then
            apache_code="NO_CONN"
        fi
        apache_status="✗ Apache ($apache_code)"
        ((FAILED_APACHE++))
    fi

    printf "%s  |  %s\n" "$nginx_status" "$apache_status"
}

echo "Starting Full Stack Test Across ${#VERSIONS[@]} PHP Versions:"
echo "${VERSIONS[*]}"
echo "--------------------------------------------------------"

for ver in "${VERSIONS[@]}"; do
    test_version "$ver"
done

echo "--------------------------------------------------------"
echo "Cleaning up test containers..."
docker compose down -v --remove-orphans >/dev/null 2>&1
echo "Done!"

TOTAL_CHECKS=$(( ${#VERSIONS[@]} * 2 ))
TOTAL_PASSED=$(( PASSED_NGINX + PASSED_APACHE ))
TOTAL_FAILED=$(( FAILED_NGINX + FAILED_APACHE ))

echo ""
echo "=== Test Summary ==="
echo "Nginx / FastCGI : ${PASSED_NGINX}/${#VERSIONS[@]} passed (${FAILED_NGINX} failed)"
echo "Apache Module   : ${PASSED_APACHE}/${#VERSIONS[@]} passed (${FAILED_APACHE} failed)"
echo "Overall Suite   : ${TOTAL_PASSED}/${TOTAL_CHECKS} checks passed"
echo "===================="

# Exit with non-zero status if any check failed
if [ $TOTAL_FAILED -ne 0 ]; then
  exit 1
fi
