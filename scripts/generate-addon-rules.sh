#! /usr/bin/env bash
set -e

# scripts/generate-addon-rules.sh
# auto-create mk/xyz.mk from input parameter "xyz" (from name images/addons/xyz/Dockerfile)

DOCKERFILE="$1"
if [ -z "$DOCKERFILE" ]; then
    echo "Usage: $0 <path-to-addon-dockerfile>" >&2
    exit 1
fi

# Extract extension name (e.g., images/addons/soap/Dockerfile -> soap)
EXT_NAME=$(basename "$(dirname "$DOCKERFILE")")

cat << EOF
# Auto-generated rules for add-on: ${EXT_NAME}
# Source: ${DOCKERFILE}

EOF

for TYPE in cli apache fpm; do
    cat << EOF
\$(BUILT_DIR)/php-${TYPE}-%-${EXT_NAME}: \$(BUILT_DIR)/php-${TYPE}-% ${DOCKERFILE} \$(DEPS_PECL)
	@echo "=== Building ${EXT_NAME} Add-on for php-${TYPE}:\$* ==="
	docker build \\
		--build-arg BASE_IMAGE=php-${TYPE}:\$* \\
		-t php-${TYPE}:\$*-${EXT_NAME} \\
		-f ${DOCKERFILE} \\
		./
	@touch \$@

EOF
done

