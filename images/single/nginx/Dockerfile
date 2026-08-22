# images/single/nginx/Dockerfile

FROM nginx:alpine

# Default healthcheck using wget (pre-installed on Alpine)
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

EXPOSE 80

