#! /usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <image_name_1> [image_name_2 ...]"
    exit 1
fi

FAILED=0

for IMAGE in "$@"; do
    echo "========================================="
    echo "Testing Image: $IMAGE"
    echo "========================================="

    # Extract tag portion (everything after the colon, e.g., 8.2-redis-pgsql-soap)
    TAG="${IMAGE##*:}"

    # Split tag tokens on hyphens
    IFS='-' read -ra TOKENS <<< "$TAG"

    ADDONS=()
    for TOKEN in "${TOKENS[@]}"; do
        # Ignore numeric version tokens (e.g. 8.2, 5.6.40)
        if [[ ! "$TOKEN" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
            ADDONS+=("$TOKEN")
        fi
    done

    if [ "${#ADDONS[@]}" -eq 0 ]; then
        echo "  [WARN] No add-on suffixes detected in tag '$TAG'. Skipping."
        echo ""
        continue
    fi

    # Retrieve loaded modules list from container
    LOADED_MODULES=$(docker run --rm "$IMAGE" php -m 2>/dev/null)

    for ADDON in "${ADDONS[@]}"; do
        # Map add-on suffix to loaded extension name patterns
        case "$ADDON" in
            pgsql)      EXT_PATTERN="pgsql|pdo_pgsql" ;;
            memcached)  EXT_PATTERN="memcached" ;;
            soap)       EXT_PATTERN="soap" ;;
            redis)      EXT_PATTERN="redis" ;;
            xdebug)     EXT_PATTERN="xdebug" ;;
            *)          EXT_PATTERN="$ADDON" ;;
        esac

        if echo "$LOADED_MODULES" | grep -Ei "^($EXT_PATTERN)$" >/dev/null; then
            echo "  [PASS] Extension module '$ADDON' is loaded"
        else
            echo "  [FAIL] Extension module '$ADDON' is NOT loaded"
            FAILED=1
        fi
    done
    echo ""
done

if [ "$FAILED" -ne 0 ]; then
    echo "Result: Add-on verification failed!"
    exit 1
fi

echo "Result: All specified add-ons verified successfully!"

