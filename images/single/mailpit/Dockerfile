# images/single/mailpit/Dockerfile

FROM axllent/mailpit:latest

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8025/api/v1/info || exit 1

# Web UI port: 8025
# SMTP server port: 1025
EXPOSE 8025 1025
