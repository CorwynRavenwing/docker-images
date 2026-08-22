# images/single/redis/Dockerfile

FROM redis:alpine

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD redis-cli ping | grep PONG || exit 1

CMD ["redis-server", "--save", "60", "1", "--loglevel", "warning"]

EXPOSE 6379
