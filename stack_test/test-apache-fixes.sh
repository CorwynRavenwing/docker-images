#! /usr/bin/env bash

# test-apache-fixes.sh

#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="php-apache:5.2.9"
CONTAINER_NAME="test-php5-apache"
PORT=8080

echo "==> 1. Starting temporary container..."
docker run -d --name "$CONTAINER_NAME" -p "$PORT":80 "$IMAGE_NAME"

# Ensure cleanup on script exit or failure
trap 'echo "==> Cleaning up..."; docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1' EXIT

# Give Apache a second to start up
sleep 2

echo "==> 2. Injecting test index.php..."
docker exec "$CONTAINER_NAME" bash -c \
  'echo "<?php echo \"PHP_EXECUTION_WORKING_\" . phpversion(); ?>" > /var/www/html/index.php'

echo "==> 3. TEST A: Verification of mod_php5 execution..."
RESPONSE=$(curl -s "http://localhost:${PORT}/index.php")

if [[ "$RESPONSE" == *"PHP_EXECUTION_WORKING_"* ]]; then
    echo " [PASS] PHP code executed successfully! Response: $RESPONSE"
elif [[ "$RESPONSE" == *"<?php"* ]]; then
    echo " [FAIL] mod_php5 failed! Apache served raw PHP source code."
    exit 1
else
    echo " [FAIL] Unexpected HTTP response: $RESPONSE"
    exit 1
fi

echo "==> 4. TEST B: Verification of normal user logging to stdout..."
# Make a request using a standard browser User-Agent
curl -s -A "Mozilla/5.0 (TestBrowser)" "http://localhost:${PORT}/index.php" >/dev/null

sleep 1
LOGS=$(docker logs "$CONTAINER_NAME" 2>&1)

if echo "$LOGS" | grep -q "TestBrowser"; then
    echo " [PASS] Standard browser traffic is correctly routed to docker stdout!"
else
    echo " [FAIL] Standard traffic did not appear in docker logs."
    exit 1
fi

echo "==> 5. TEST C: Verification of healthcheck (curl) log suppression..."
# Clear logs baseline by checking before curl ping
curl -s -A "curl/7.88.1" "http://localhost:${PORT}/index.php" >/dev/null

sleep 1
UPDATED_LOGS=$(docker logs "$CONTAINER_NAME" 2>&1)

if echo "$UPDATED_LOGS" | grep -q "curl/7.88.1"; then
    echo " [FAIL] curl healthcheck request was logged! Suppression filter failed."
    exit 1
else
    echo " [PASS] Healthcheck curl ping was suppressed from access logs!"
fi

echo ""
echo "🎉 ALL TESTS PASSED! Legacy Apache container is fully operational."
