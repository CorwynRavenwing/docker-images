# /usr/bin/env bash

# stack_test/test-stack.sh

set -euo pipefail

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="${ROOT_DIR}/example"

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

cleanup() {
    log_info "Tearing down compose environment..."
    if [ -d "${EXAMPLE_DIR}" ]; then
        cd "${EXAMPLE_DIR}" && docker compose down -v --remove-orphans || true
    fi
}

trap cleanup EXIT

log_info "Step 1: Building all images via Makefile..."
cd "${ROOT_DIR}"
make all

log_info "Step 2: Spinning up container stack..."
cd "${EXAMPLE_DIR}"
docker compose up -d --wait

log_info "Step 3: Validating container health statuses..."
FAILED_CONTAINERS=0

# Get all running container IDs in this compose project
CONTAINERS=$(docker compose ps -q)

if [ -z "${CONTAINERS}" ]; then
    log_error "No running containers found in compose stack!"
    exit 1
fi

for CONTAINER in ${CONTAINERS}; do
    NAME=$(docker inspect --format='{{.Name}}' "${CONTAINER}" | tr -d '/')
    HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "${CONTAINER}")

    if [ "${HEALTH}" = "healthy" ] || [ "${HEALTH}" = "no-healthcheck" ]; then
        log_success "Container '${NAME}' is status: ${HEALTH}"
    else
        log_error "Container '${NAME}' is UNHEALTHY! (status: ${HEALTH})"
        FAILED_CONTAINERS=$((FAILED_CONTAINERS + 1))

        # Display recent healthcheck logs for debugging
        echo "--- Healthcheck Logs for ${NAME} ---"
        docker inspect --format='{{json .State.Health}}' "${CONTAINER}" || true
        echo "-------------------------------------"
    fi
done

if [ "${FAILED_CONTAINERS}" -gt 0 ]; then
    log_error "Validation failed: ${FAILED_CONTAINERS} container(s) are unhealthy."
    exit 1
fi

log_success "All stack containers built, booted, and passed health checks successfully!"
