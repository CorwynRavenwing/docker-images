# images/single/memcached/Dockerfile

FROM memcached:alpine

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD nc -z 127.0.0.1 11211 || exit 1

# Set default memory limit to 64MB (-m 64)
CMD ["memcached", "-m", "64"]

EXPOSE 11211
