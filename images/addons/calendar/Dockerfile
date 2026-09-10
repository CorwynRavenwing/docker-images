# images/addons/calendar/Dockerfile

ARG BASE_IMAGE=scratch
FROM ${BASE_IMAGE}

# Compile and enable the built-in PHP calendar extension
RUN docker-php-ext-install calendar
