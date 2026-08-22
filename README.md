# PHP Cross-Version Docker Library (PHP 5.0 – 8.5)

A standardized, multi-architecture Docker image library spanning 22+ years of PHP releases across 18 distinct versions (5.0 through 8.5). Designed to support both Nginx (FastCGI/FPM) and Apache (mod_php) deployment patterns with automated test validation.

## 🚀 Version & Architecture Matrix

All images are standardized to listen on standard interfaces:

* Nginx / FastCGI Stack: PHP-FPM / spawn-fcgi exposed on TCP port 9000.
* Apache Stack: Apache 2.4 with embedded mod_php (apache2handler) exposed on TCP port 80.

| PHP Versions | Nginx / FastCGI | Apache SAPI | Build Strategy | Base OS | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **5.0 – 5.2** | `cgi-fcgi` (via spawn-fcgi) | `apache2handler` | Multi-stage C Compilation | • Debian Jessie (`archive.debian.org`)<br>• Uses `mpm_prefork`<br>• C symbol mapping enabled<br>• Wrapped with `spawn-fcgi` on 9000 | These versions predate native PHP-FPM, so they rely on compiling the CGI binary and wrapping it with spawn-fcgi on port 9000 |
| **5.3 – 5.5** | `fpm-fcgi` (Compiled FPM) | `apache2handler` | Multi-stage C Compilation | • Debian Jessie (`archive.debian.org`)<br>• Uses `mpm_prefork`<br>• Native compiled PHP-FPM | PHP 5.3 introduced native FPM into core source code, so these compile FPM directly. |
| **5.6 – 8.5** | `fpm-fcgi` | `apache2handler` | Docker Hub (`php:PHP_VERSION`) | • Upstream official Debian images<br>• Dynamic base OS (Bookworm/Bullseye/Buster) | Upstream official Docker images handle the base OS layering automatically per version release. |

## 🛠️ Key Technical Solutions & Standardization

1. Apache 2.4 C Symbol Mappings (PHP 5.0–5.2):

    Legacy PHP 5 builds require mapping deprecated Apache C symbols via CPPFLAGS:
    -Dunixd_config=ap_unixd_config -Dap_get_server_version=ap_get_server_banner

1. Apache MPM Thread Safety (mpm_prefork):

    All legacy Apache builds force mpm_prefork to maintain compatibility with Non-Thread Safe (NTS) PHP module builds.

1. Universal FastCGI Binding:

    FPM and spawn-fcgi services are configured to bind to 0.0.0.0:9000 inside containers, ensuring reliable cross-container communication with Nginx.

1. Hardened Dockerfile Build Arguments:

    ARG PHP_VERSION defaults to sentinel values (REQUIRED_BUILD_ARG_MISSING) across Dockerfiles to prevent silent fallback tagging errors during image creation.

1. Dual Tagging & Patch Mapping (realversion):

    A pure Makefile lookup map resolves minor aliases (e.g., 7.4) to their latest immutable patch releases (e.g., 7.4.33). Builds automatically generate dual image tags (e.g., php-fpm:7.4 and php-fpm:7.4.33). Passing explicit patch versions directly (e.g., 5.1.3) passes through unmodified.

1. Host Tarball Caching (downloads/):

    Source archives for legacy compilation (5.0–5.5) are cached on the host in ./downloads/ using atomic curl routines with .tmp staging and URL fallback (PHP Distributions $\rightarrow$ Museum). This prevents redundant network downloads and protects against incomplete/corrupted tarballs.

1. Native Container Healthchecks:

    Web and FPM images define native HEALTHCHECK directives (curl -f for Apache, nc -z for FPM), allowing orchestration tools and test suites to use docker compose up -d --wait deterministically.

## 📋 Prerequisites

* Docker: Engine 20.10+
* Docker Compose: v2.0+
* GNU Make: 4.0+
* curl & bash (for test execution)

## ⚙️ Makefile Targets Reference

The root Makefile manages the compilation, tagging, cleanup, and testing lifecycle across all 18 versions.

### Build Targets

| Make Command | Description |
| :--- | :--- |
| `make all` | Builds all 18 PHP versions across base, FPM, and Apache targets. |
| `make php-base-<VER>` | Builds the base compilation/system image for a specific version (e.g., `make php-base-5.0`). |
| `make php-apache-<VER>` | Builds the monolithic Apache module image for a specific version (e.g., `make php-apache-7.4`). |
| `make php-cli-<VER>` | Builds the Command Line PHP image for a specific version (e.g., `make php-cli-7.4`). |
| `make php-fpm-<VER>` | Builds the standalone Nginx/FPM image for a specific version (e.g., `make php-fpm-8.1`). |
| `make php-<flavor>-<VER>-<addon>` | Builds a base image with a specific add-on layer applied (e.g., `make php-cli-8.1-redis`, `make php-apache-7.4-ldap-redis`). |

### Testing Targets

| Make Command      | Description                                                                |
| :---              | :---                                                                       |
| `make test`       | Runs a test of each image to verify it has the correct version |
| `make test-stack` | Executes the automated test suite across all PHP versions in `stack_test/` |

### Maintenance & Cleanup Targets

| Make Command        | Description |
| :---                | :--- |
| `make clean`        | Safely removes local state markers, causing all images to need being rebuilt. |
| `make prune`        | Safely prunes dangling intermediate build stages (<none>:<none>). |
| `make clean-downloads` | Deletes host-cached source tarballs in `downloads/`. |
| `make clean-cache`  | Clears BuildKit / Docker builder cache to free system disk space. |
| `make clean-images` | Forces removal of all generated `php-*` Docker images from the local daemon. |
| `make clean-all`    | Full reset: Executes `clean-images` followed by `clean-cache`. |
| `make disk-usage`   | Displays Docker system space allocation alongside an ordered size table of all `php-*` images. |

## Add-on System & Stacking

### Optional Add-on Modules

Add-ons are stackable layers that build on top of any base PHP image (`cli`, `fpm`, `apache`).

| Add-on Layer | Extension / Features | System Dependencies | Primary Use Case |
| :--- | :--- | :--- | :--- |
| `add-tsql` | `pdo_dblib` / FreeTDS | `freetds-dev` | Microsoft SQL Server / Sybase connections |
| `add-xdebug` | `xdebug` | Built via PECL | Remote debugging & code coverage reports |
| `add-imagick` | `imagick` | `imagemagick`, `libmagickwand-dev` | Advanced image manipulation & thumbnailing |
| `add-ldap` | `ldap` | `libldap2-dev` | Enterprise Directory / Active Directory auth |
| `add-redis` | `redis` | Built via PECL | High-performance caching & session storage |

### Stacking Add-on Layers

Add-ons accept the base image as a build argument (`ARG BASE_IMAGE`). This allows arbitrary stacking of features without modifying base Dockerfiles.

#### Build Target Pattern
`php-{flavor}-{version}-{addon1}[-{addon2}...]`

#### Examples:
```bash
# Base CLI image + Redis
make php-cli-8.1-redis

# Multi-layered build: CLI -> TSQL -> Xdebug -> Imagick
make php-cli-8.1-tsql-xdebug-imagick

# Apache web server + LDAP + Redis
make php-apache-7.4-ldap-redis
```

* **Build Context Note:** Standard add-ons use `images/add-<name>` as their build context to keep builds clean. Add-ons requiring host-cached files from `./downloads/` execute using the project root context (`-f images/add-<name>/Dockerfile ./`) instead.

### Directory Structure

```text
.
├── Makefile              # Unified build orchestration & pattern recipes
├── mk/                   # *.mk Makefile include files: auto-created from addons/
├── downloads/            # Host-cached archive directory (parsed/created at runtime)
├── built/                # Build sentinel markers (touch files tracking target completion)
├── scripts/              # bash scripts used in various Dockerfiles
├── example/              # a docker-compose.yml file using several of these images
├── stack-test/           # several scripts used to test images for completeness
├── shared/default.conf   # default .conf file for FPM.  (Unsure if it is still used) 
└── images/
    ├── legacy/           # old-style (pre-5.6) Dockerfiles
    .   ├── php-base-legacy/    # base for the other php-*-legacy images
    .   ├── php-apache-legacy/
    .   ├── php-cli-legacy/
    .   └── php-fpm-legacy/
    ├── modern/           # new-style (5.6 and later) Dockerfiles
    .   ├── php-apache/
    .   ├── php-cli/      # note: there is no php-base/ upstream of these three
    .   └── php-fpm/
    ├── addons/           # Dockerfiles that add a layer to another image
    .   ├── imagick/      # add ImageMagick layer
    .   ├── ldap/         # add LDAP layer
    .   ├── redis/        # add Redis layer
    .   ├── tsql/         # add MS SQL / FreeTDS layer
    .   ├── xdebug/       # add Xdebug layer
    .   └── ...
    ├── single/           # Dockerfile for standalone images
    .   ├── mysql/        # produces image 'local-mysql'
    .   ├── nginx/
    .   ├── pgsql/
    .   ├── redis/
    .   └── ...
    └── heavy/            # More standalone images that are too large for 'make all'
        └── tsql/         # image 'local-tsql', a Microsoft SQL server



```

### Verification Quick Reference

Run these ephemeral commands to verify extension functionality:

```bash
# Test Redis
docker run --rm php-cli:8.1-redis php -m | grep -i redis

# Test Imagick
docker run --rm php-cli:8.1-imagick php -r "echo class_exists('Imagick') ? 'OK\n' : 'FAIL\n';"

# Test LDAP
docker run --rm php-cli:8.1-ldap php -r "echo extension_loaded('ldap') ? 'OK\n' : 'FAIL\n';"

# Test Multi-stacked container (TSQL + Xdebug + Redis)
docker run --rm php-cli:8.1-tsql-xdebug-redis php -m | grep -E 'dblib|xdebug|redis'
```

### How to Add a New Extension Layer

To create a new add-on (e.g., `add-memcached`):

1. **Create the Dockerfile** at `images/add-memcached/Dockerfile`:
   ```dockerfile
   ARG BASE_IMAGE
   FROM ${BASE_IMAGE}

   RUN set -e; \
       apt-get update && apt-get install -y --no-install-recommends libmemcached-dev \
       && rm -rf /var/lib/apt/lists/*

   RUN set -e; \
       if command -v pecl >/dev/null 2>&1; then \
           pecl install memcached && docker-php-ext-enable memcached ; \
       fi
    ```

1. **Add Makefile Pattern Rules**:
    ```Makefile
    php-%-memcached: php-%
        @echo "=== Building Memcached Add-on for $* ==="
        docker build \
            --build-arg BASE_IMAGE=$* \
            -t $*-memcached \
            images/add-memcached
        @touch $(BUILT_DIR)/$@
    ```

## 🧪 Test Suite (stack_test/)

The test suite validates both SAPI endpoints for any specified PHP version using a dynamic docker-compose.yml harness.

* Port 8080: Nginx FastCGI Reverse Proxy -> test-php-fpm:9000
* Port 8081: Apache 2.4 Monolithic (mod_php)

### Running Tests

Execute the full suite across all 18 versions:

```bash
make test-stack
# OR
./stack_test/test_all.sh
```

Execute tests for specific version(s) only:

```bash
./stack_test/test_all.sh 5.0 5.3 8.1
# OR
./stack_test/test_all.sh 5.1.3 5.5.38 8.1.12
```

### Sample Output

```
Starting Stack Test Across 18 PHP Version(s):
5.0 5.1 5.2 5.3 5.4 5.5 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3 8.4 8.5
--------------------------------------------------------
Testing PHP 5.0  => ✓ Nginx (FPM/CGI)  |  ✓ Apache
Testing PHP 5.1  => ✓ Nginx (FPM/CGI)  |  ✓ Apache
...
Testing PHP 8.5  => ✓ Nginx (FPM/CGI)  |  ✓ Apache
--------------------------------------------------------
Cleaning up test containers...

=== Test Summary ===
Nginx / FastCGI : 18/18 passed (0 failed)
Apache Module   : 18/18 passed (0 failed)
Overall Suite   : 36/36 checks passed
====================
```

## 💻 Usage Examples

1. Standalone Apache Container

    Run a self-contained Apache + PHP 7.4 server serving code from ./src:


    ```bash
    docker run -d \
      --name my-php-app \
      -p 80:80 \
      -v $(pwd)/src:/var/www/html \
      php-apache:7.4
    ```

1. Nginx + PHP-FPM Composition

    Use PHP-FPM 8.2 with an Nginx container via Docker Compose:

    ```yaml
    version: '3.8'

    services:
      php:
        image: php-fpm:8.2
        volumes:
          - ./src:/var/www/html

      web:
        image: nginx:alpine
        ports:
          - "80:80"
        volumes:
          - ./src:/var/www/html
          - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
        depends_on:
          - php
    ```

## Infrastructure & Service Orchestration

This repository provides both the PHP matrix images and a suite of lightweight standalone infrastructure services (`single/`) and heavy database tools (`heavy/`).

1. Image Categories & Tags

| Category | Makefile Group | Tagging Pattern | Examples |
| PHP Matrix Base | `make base` | `php-base:<version>-<flavor>` | `php-base:8.2-fpm` |
| PHP with Add-ons | Matrix Target | `php-<flavor>:<version>-<addons>` | `php-fpm:8.2-redis-pgsql-soap` |
| Lightweight Services | `make single` / `make all` | `local-<service>:latest` | `local-nginx:latest`, `local-redis:latest` |
| Resource Services | `make heavy` | `local-<service>:latest` | `local-tsql:latest` |

1. Build Tooling

The build system tracks built images using flag files in `built/``.

```bash
# Build standard PHP matrix and all single/ infrastructure services
make all

# Build only lightweight services (nginx, mysql, pgsql, redis, memcached, mailpit)
make single

# Build heavy opt-in services on demand (e.g. MS SQL Server)
make heavy
make local-tsql

# Rebuild a single service after updating its Dockerfile
rm built/local-nginx
make local-nginx
```

1. Orchestrating a Local Stack

An example development environment is provided in `example/docker-compose.yml`. It uses native Docker `HEALTHCHECK` definitions and `condition: service_healthy` to ensure database and caching services are ready before starting PHP and Nginx.

To spin up the example environment:

```bash
cd example
docker compose up -d --wait
```

To stop and tear down containers while preserving volume data:

```bash
docker compose down
```

# Appendix A: PHP Release History

## PHP 1 & 2 Series

- PHP 1.0 (1995)

- PHP 2.0 / PHP/FI (1997)

## PHP 3 Series

- PHP 3.0 (1998)

## PHP 4 Series

- PHP 4.0 (2000)
- PHP 4.1 (2001)
- PHP 4.2 (2002)
- PHP 4.3 (2002)
- PHP 4.4 (2005)

## PHP 5 Series

- PHP 5.0 (2004)
- PHP 5.1 (2005)
- PHP 5.2 (2006)
- PHP 5.3 (2009)
- PHP 5.4 (2012)
- PHP 5.5 (2013)
- PHP 5.6 (2014)

## PHP 6 Series

- PHP 6.x — Skipped / Never officially released

## PHP 7 Series

- PHP 7.0 (2015)
- PHP 7.1 (2016)
- PHP 7.2 (2017)
- PHP 7.3 (2018)
- PHP 7.4 (2019)

## PHP 8 Series

- PHP 8.0 (2020)
- PHP 8.1 (2021)
- PHP 8.2 (2022)
- PHP 8.3 (2023)
- PHP 8.4 (2024)
- PHP 8.5 (2025)

# Appendix B: The Official Debian Packaging History

## PHP 1 & 2 (1995–1997):
    - Debian was in its infancy (Debian 1.1 released in 1996). PHP was distributed as raw C source code or CGI executables, so it wasn't packaged into official .deb software repositories yet.

## PHP 3 & 4 (1998–2004):
    - Official Debian packages began around Debian 2.x ("Hamm" and "Potato").

## PHP 5, 7, and 8:
    - Debian follows a strict stable-release cycle (releasing a new OS version roughly every two years).
    - Because of this schedule, official Debian releases only shipped with whichever stable PHP version was current at freeze time, skipping intermediate minor releases in their main repositories:

| Debian Version        | Release Year | Included Official PHP Version  |
| :---                  | :---         | :---                           |
| Debian 8 (Jessie)     | 2015         | PHP 5.6                        |
| Debian 9 (Stretch)	| 2017		   | PHP 7.0                        |
| Debian 10 (Buster)	| 2019		   | PHP 7.3                        |
| Debian 11 (Bullseye)	| 2021		   | PHP 7.4                        |
| Debian 12 (Bookworm)	| 2023		   | PHP 8.2                        |
| Debian 13 (Trixie)	| Upcoming	   | PHP 8.4                        |

- (Notice how versions like PHP 7.1, 7.2, 8.0, and 8.1 were never the default PHP version in a stable Debian release).

## How Debian Users Got Every Version
- To bridge this gap, long-time Debian core maintainer Ondřej Surý created the official third-party PPA/DPA repository (deb.sury.org). This repository packages every single minor version of PHP (from 5.6 through 8.5) as native .deb files for Debian systems.

