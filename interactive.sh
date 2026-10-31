#! /usr/bin/env bash

docker run --rm -it \
  -e PHP_VERSION=5.0.5 \
  debian:jessie-slim \
  bash
