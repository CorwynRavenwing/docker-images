# docker-images/Makefile

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "========================================================================"
	@echo "                     PHP DOCKER STACK BUILD SYSTEM                      "
	@echo "========================================================================"
	@echo ""
	@echo " Usage Syntax:"
	@echo "   make php-<sapi>:<version>[-addon1-addon2...]"
	@echo ""
	@echo " Primary Targets:"
	@echo "   make all               Build default base images"
	@echo "   make test-addons       Build and verify add-on extension loading"
	@echo "   make generate-add-mk   Regenerate mk/*.mk rules from images/add-*"
	@echo "   make clean             Remove built/ sentinel files"
	@echo "   make clean-all         Remove built/ sentinels and generated mk/*.mk files"
	@echo ""
	@echo " Example Commands:"
	@echo "   make php-cli:8.2"
	@echo "   make php-apache:5.6.40-soap"
	@echo "   make php-fpm:8.1-redis-pgsql-xdebug"
	@echo ""
	@echo "========================================================================"

IMAGE_DIR     := images
BUILT_DIR     := built
DOWNLOADS_DIR := downloads
MK_DIR        := mk

AUTO_MKDIR    := $(IMAGE_DIR) $(BUILT_DIR) $(DOWNLOADS_DIR) $(MK_DIR)
# parse-time directory creation
$(shell mkdir -vp $(AUTO_MKDIR))

# Keep all intermediate files
.SECONDARY:

# Define version ranges
# even legacy-er versions (not trying right now)
ANCIENT_VERSIONS := \
	1.0 \
	2.0 \
	3.0 \
	4.0 4.1 4.2 4.3 4.4
# Legacy 5.x versions (built from source)
LEGACY_VERSIONS := \
	5.0 5.1 5.2 5.3 5.4 5.5
# Modern versions (using standard Dockerfiles)
MODERN_VERSIONS := \
	5.6 \
	7.0 7.1 7.2 7.3 7.4 \
	8.0 8.1 8.2 8.3 8.4 8.5

# LEGACY_PATTERNS := 5.0% 5.1% 5.2% 5.3% 5.4% 5.5%
LEGACY_PATTERNS := $(addsuffix %,$(LEGACY_VERSIONS))

# Function: Map minor version alias (e.g., 5.1) to latest patch (5.1.6), or pass exact patch through (5.1.3)
# --- VERSION LOOKUP MAP ---
REAL_VER_5.0 := 5.0.5
REAL_VER_5.1 := 5.1.6
REAL_VER_5.2 := 5.2.17
REAL_VER_5.3 := 5.3.29
REAL_VER_5.4 := 5.4.45
REAL_VER_5.5 := 5.5.38
REAL_VER_5.6 := 5.6.40
REAL_VER_7.0 := 7.0.33
REAL_VER_7.1 := 7.1.33
REAL_VER_7.2 := 7.2.34
REAL_VER_7.3 := 7.3.33
REAL_VER_7.4 := 7.4.33
REAL_VER_8.0 := 8.0.30
REAL_VER_8.1 := 8.1.31
REAL_VER_8.2 := 8.2.27
REAL_VER_8.3 := 8.3.16
REAL_VER_8.4 := 8.4.3

# Look up mapped patch version; fall back to input version ($1) if not found
realversion = $(or $(REAL_VER_$(1)),$(1))

# never show "entering directory '$CWD'; leaving directory '$CWD'"
MAKEFLAGS += --no-print-directory

# 1. Dependency-only rules (no recipes)
$(foreach v,$(LEGACY_VERSIONS),$(BUILT_DIR)/php-fpm-$(v)%):    $(IMAGE_DIR)/php-fpm-legacy/Dockerfile
$(foreach v,$(LEGACY_VERSIONS),$(BUILT_DIR)/php-apache-$(v)%): $(IMAGE_DIR)/php-apache-legacy/Dockerfile
$(foreach v,$(LEGACY_VERSIONS),$(BUILT_DIR)/php-cli-$(v)%):    $(IMAGE_DIR)/php-cli-legacy/Dockerfile

$(foreach v,$(MODERN_VERSIONS),$(BUILT_DIR)/php-fpm-$(v)%):    $(IMAGE_DIR)/php-fpm/Dockerfile
$(foreach v,$(MODERN_VERSIONS),$(BUILT_DIR)/php-apache-$(v)%): $(IMAGE_DIR)/php-apache/Dockerfile
$(foreach v,$(MODERN_VERSIONS),$(BUILT_DIR)/php-cli-$(v)%):    $(IMAGE_DIR)/php-cli/Dockerfile

# --- DOCKERFILE PREREQUISITES (No recipes, just dependency tracking) ---
# --- legacy versions
$(addprefix $(BUILT_DIR)/php-fpm-,$(LEGACY_PATTERNS)): $(IMAGE_DIR)/php-fpm-legacy/Dockerfile
$(addprefix $(BUILT_DIR)/php-cli-,$(LEGACY_PATTERNS)): $(IMAGE_DIR)/php-cli-legacy/Dockerfile
$(addprefix $(BUILT_DIR)/php-apache-,$(LEGACY_PATTERNS)): $(IMAGE_DIR)/php-apache-legacy/Dockerfile
# --- modern versions
$(BUILT_DIR)/php-fpm-%:    $(IMAGE_DIR)/php-fpm/Dockerfile
$(BUILT_DIR)/php-cli-%:    $(IMAGE_DIR)/php-cli/Dockerfile
$(BUILT_DIR)/php-apache-%: $(IMAGE_DIR)/php-apache/Dockerfile

# Default fallback for arbitrary unlisted modern patch versions (e.g. 8.1.12)

# 1a. Discover all image folders
DOCKERFILES := $(wildcard $(IMAGE_DIR)/*/Dockerfile)
# 1b. Extract ONLY the bare directory names
# patsubst transforms "image/foo/Dockerfile" directly into "foo"
ALL_IMAGES  := $(patsubst $(IMAGE_DIR)/%/Dockerfile,%,$(DOCKERFILES))

# 2. Define the three PHP matrix image names
PHP_IMAGE_TYPES := php-cli php-apache php-fpm
PHP_BASE_TYPES := php-base-legacy php-cli-legacy php-apache-legacy php-fpm-legacy

KNOWN_TYPES  := $(PHP_IMAGE_TYPES) $(PHP_BASE_TYPES)
UNKNOWN_TYPES := $(filter-out $(KNOWN_TYPES),$(ALL_IMAGES))
OTHER_IMAGES := $(filter-out add-%,$(UNKNOWN_TYPES))

# 1. Standard Flag Files (e.g., built/php-cli-8.3)
PHP_TARGETS           := $(foreach type,$(PHP_IMAGE_TYPES),$(foreach ver,$(MODERN_VERSIONS),$(type)-$(ver)))
PHP_FLAG_FILES        := $(addprefix $(BUILT_DIR)/,$(PHP_TARGETS))

# 2. Legacy Flag Files (e.g., built/php-cli-5.1)
PHP_LEGACY_TARGETS    := $(foreach type,$(PHP_IMAGE_TYPES),$(foreach ver,$(LEGACY_VERSIONS),$(type)-$(ver)))
PHP_LEGACY_FLAG_FILES := $(addprefix $(BUILT_DIR)/,$(PHP_LEGACY_TARGETS))

# 3. Legacy Base Flag Files (e.g., built/php-base-legacy-5.1)
LEGACY_BASE_FLAGS     := $(addprefix $(BUILT_DIR)/php-base-legacy-,$(LEGACY_VERSIONS))

# 4. Other targets (e.g. built/mysql-6.0)
OTHER_FLAG_FILES      := $(addprefix $(BUILT_DIR)/,$(OTHER_IMAGES))

ALL_PHP_TARGETS       := $(PHP_TARGETS) $(PHP_LEGACY_TARGETS)

# 3. Test targets
PHP_TEST_TARGETS      := $(addprefix test-,$(ALL_PHP_TARGETS))
OTHER_TEST_TARGETS    := $(addprefix test-,$(OTHER_IMAGES))

# Flavor-specific test lists
CLI_TEST_TARGETS      := $(filter test-php-cli-%, $(PHP_TEST_TARGETS))
APACHE_TEST_TARGETS   := $(filter test-php-apache-%, $(PHP_TEST_TARGETS))
FPM_TEST_TARGETS      := $(filter test-php-fpm-%, $(PHP_TEST_TARGETS))

.PHONY: all clean list list-tests test test-cli test-apache test-fpm

all: $(PHP_FLAG_FILES) $(PHP_LEGACY_FLAG_FILES) $(OTHER_FLAG_FILES)

all-check:
	@echo "make all -> $(PHP_FLAG_FILES) $(PHP_LEGACY_FLAG_FILES) $(OTHER_FLAG_FILES)"

# --- CLEAN UNIFIED BASE RULE ---
# - uses context trick so ./downloads/ is available
$(BUILT_DIR)/php-base-legacy-%: $(IMAGE_DIR)/php-base-legacy/Dockerfile
	$(eval REAL_VER := $(call realversion,$*))
	@"$(MAKE)" $(DOWNLOADS_DIR)/php-$(REAL_VER).tar.bz2
	@echo "=== Building LEGACY BASE image: php-base-legacy:$(REAL_VER) ==="
	docker build \
		--build-arg PHP_VERSION=$(REAL_VER) \
		-t php-base-legacy:$* \
		-t php-base-legacy:$(REAL_VER) \
		-f $(IMAGE_DIR)/php-base-legacy/Dockerfile \
		./
	@touch $(BUILT_DIR)/php-base-legacy-$(REAL_VER)
	@touch $@

# 2. Map Legacy Targets to depend on their Base Image marker
# For any 5.0-5.5 version (including patch tags), enforce base image completion first
$(foreach v,$(LEGACY_VERSIONS),$(BUILT_DIR)/php-fpm-$(v)%):    $(BUILT_DIR)/php-base-$(v)%
$(foreach v,$(LEGACY_VERSIONS),$(BUILT_DIR)/php-apache-$(v)%): $(BUILT_DIR)/php-base-$(v)%
$(foreach v,$(LEGACY_VERSIONS),$(BUILT_DIR)/php-cli-$(v)%):    $(BUILT_DIR)/php-base-$(v)%

# Define the legacy target subsets
LEGACY_CLI_TARGETS := $(filter $(BUILT_DIR)/php-cli-%, $(PHP_LEGACY_FLAG_FILES))
LEGACY_APACHE_TARGETS := $(filter $(BUILT_DIR)/php-apache-%, $(PHP_LEGACY_FLAG_FILES))
LEGACY_FPM_TARGETS := $(filter $(BUILT_DIR)/php-fpm-%, $(PHP_LEGACY_FLAG_FILES))

# Make legacy flavor flag files depend on their corresponding php-base-legacy flag file
$(LEGACY_CLI_TARGETS): $(BUILT_DIR)/php-cli-5.%: $(BUILT_DIR)/php-base-legacy-5.%
$(LEGACY_APACHE_TARGETS): $(BUILT_DIR)/php-apache-5.%: $(BUILT_DIR)/php-base-legacy-5.%
$(LEGACY_FPM_TARGETS): $(BUILT_DIR)/php-fpm-5.%: $(BUILT_DIR)/php-base-legacy-5.%

# --- RE-UNIFIED BUILD RECIPES ---
# - legacy branch uses context trick so ./downloads/ is available
# - modern branch uses context trick so ./scripts/ is available


# NOTE: possible later refactor:
# Dynamic prerequisite selection: Reject hyphens, otherwise route to legacy or modern Dockerfile
# $(BUILT_DIR)/php-apache-%: $$(if $$(findstring -,$$*),FORCE_NONEXISTENT,$$(if $$(filter $$(LEGACY_PATTERNS),$$*),$(IMAGE_DIR)/php-apache-legacy/Dockerfile,$(IMAGE_DIR)/php-apache/Dockerfile))
# this would allow it to depend on the correct Dockerfile dynamically


.SECONDEXPANSION:
# SECONDEXPANSION plus FORCE_NONEXISTENT is to forbid this pattern from matching
# any tails that contain a hyphen (e.g. php-cli-5.0-addonname), which need to match
# a %-addonname pattern later instead.
# When this refactor happens, the DEPS_APT dependency need not happen for the Legacy branch
# ==============================================================================
# PHP-CLI
# ==============================================================================
$(BUILT_DIR)/php-cli-%: $$(if $$(findstring -,$$*),FORCE_NONEXISTENT,$(DEPS_APT))
	$(eval REAL_VER := $(call realversion,$*))
	@set -e ; \
	if [ -n "$(filter $(LEGACY_PATTERNS),$*)" ]; then \
		echo "=== Building LEGACY CLI image: php-cli:$* ($(REAL_VER)) ===" ; \
		"$(MAKE)" $(BUILT_DIR)/php-base-legacy-$* ; \
		"$(MAKE)" $(DOWNLOADS_DIR)/php-$(REAL_VER).tar.bz2 ; \
		docker build \
			--build-arg PHP_VERSION=$(REAL_VER) \
			-t php-cli:$* \
			-t php-cli:$(REAL_VER) \
			-f $(IMAGE_DIR)/php-cli-legacy/Dockerfile \
			./ ; \
	else \
		echo "=== Building MODERN CLI image: php-cli:$* ($(REAL_VER)) ===" ; \
		docker build \
			--build-arg PHP_VERSION=$(REAL_VER) \
			-t php-cli:$* \
			-t php-cli:$(REAL_VER) \
			-f $(IMAGE_DIR)/php-cli/Dockerfile \
			./ ; \
	fi
	@touch $(BUILT_DIR)/php-cli-$*
	@touch $(BUILT_DIR)/php-cli-$(REAL_VER)

# ==============================================================================
# PHP-APACHE
# ==============================================================================
$(BUILT_DIR)/php-apache-%: $$(if $$(findstring -,$$*),FORCE_NONEXISTENT,$(DEPS_APT))
	$(eval REAL_VER := $(call realversion,$*))
	@set -e ; \
	if [ -n "$(filter $(LEGACY_PATTERNS),$*)" ]; then \
		echo "=== Building LEGACY APACHE image: php-apache:$* ($(REAL_VER)) ===" ; \
		"$(MAKE)" $(BUILT_DIR)/php-base-legacy-$* ; \
		"$(MAKE)" $(DOWNLOADS_DIR)/php-$(REAL_VER).tar.bz2 ; \
		docker build \
			--build-arg PHP_VERSION=$(REAL_VER) \
			-t php-apache:$* \
			-t php-apache:$(REAL_VER) \
			-f $(IMAGE_DIR)/php-apache-legacy/Dockerfile \
			./ ; \
	else \
		echo "=== Building MODERN APACHE image: php-apache:$* ($(REAL_VER)) ===" ; \
		docker build \
			--build-arg PHP_VERSION=$(REAL_VER) \
			-t php-apache:$* \
			-t php-apache:$(REAL_VER) \
			-f $(IMAGE_DIR)/php-apache/Dockerfile \
			./ ; \
	fi
	@touch $(BUILT_DIR)/php-apache-$*
	@touch $(BUILT_DIR)/php-apache-$(REAL_VER)

# ==============================================================================
# PHP-FPM
# ==============================================================================
$(BUILT_DIR)/php-fpm-%: $$(if $$(findstring -,$$*),FORCE_NONEXISTENT,$(DEPS_APT))
	$(eval REAL_VER := $(call realversion,$*))
	@set -e ; \
	if [ -n "$(filter $(LEGACY_PATTERNS),$*)" ]; then \
		echo "=== Building LEGACY FPM image: php-fpm:$* ($(REAL_VER)) ===" ; \
		"$(MAKE)" $(BUILT_DIR)/php-base-legacy-$* ; \
		"$(MAKE)" $(DOWNLOADS_DIR)/php-$(REAL_VER).tar.bz2 ; \
		docker build \
			--build-arg PHP_VERSION=$(REAL_VER) \
			-t php-fpm:$* \
			-t php-fpm:$(REAL_VER) \
			-f $(IMAGE_DIR)/php-fpm-legacy/Dockerfile \
			./ ; \
	else \
		echo "=== Building MODERN FPM image: php-fpm:$* ($(REAL_VER)) ===" ; \
		docker build \
			--build-arg PHP_VERSION=$(REAL_VER) \
			-t php-fpm:$* \
			-t php-fpm:$(REAL_VER) \
			-f $(IMAGE_DIR)/php-fpm/Dockerfile \
			./ ; \
	fi
	@touch $(BUILT_DIR)/php-fpm-$*
	@touch $(BUILT_DIR)/php-fpm-$(REAL_VER)

# Rule for single-build / non-matrix standalone images (tagged :latest)
$(BUILT_DIR)/%: $(IMAGE_DIR)/%/Dockerfile
	@echo "=================================================="
	@echo "Building standalone image: $*:latest"
	@echo "=================================================="
	docker build -t $*:latest $(IMAGE_DIR)/$*
	@touch $@

# Alias rule: map short targets (e.g. php-fpm-8.1.12) to real marker files (built/php-fpm-8.1.12)
.PHONY: php-%
php-%: $(BUILT_DIR)/php-% ;

# ==============================================================================
# Colon-to-Hyphen CLI Aliases
# ==============================================================================

.PHONY: php-cli\:% php-fpm\:% php-apache\:%

# note: `@:` is a shell no-op, satisfying the target without touching the filesystem
php-cli\:%: php-cli-%
	@:

php-fpm\:%: php-fpm-%
	@:

php-apache\:%: php-apache-%
	@:

# --- DOWNLOAD & CACHE RULE ---

URL_PRIMARY = https://www.php.net/distributions/
URL_MUSEUM = https://museum.php.net/php5/

$(DOWNLOADS_DIR)/php-%.tar.bz2:
	@echo "=== Downloading PHP $* source tarball ==="
	@curl -fsSL "$(URL_PRIMARY)/$(@F)" -o $@.tmp \
	|| curl -fsSL "$(URL_MUSEUM)/$(@F)" -o $@.tmp
	@mv $@.tmp $@

# ==============================================================================
# Auto-generated add-on Makefiles
# ==============================================================================

# 1. Discover all add-on names by scanning images/add-*/Dockerfile
ADDON_DIRS := $(wildcard $(IMAGE_DIR)/add-*/Dockerfile)
ADDONS     := $(patsubst $(IMAGE_DIR)/add-%/Dockerfile,%,$(ADDON_DIRS))
ADDON_MK   := $(patsubst %,$(MK_DIR)/%.mk,$(ADDONS))

-include $(ADDON_MK)

.PHONY: mk clean-mk

mk: $(ADDON_MK)

clean-mk:
	@rm -vr $(MK_DIR)

# printf turns doubled \\, %%, or $$ into a single \, %, or $
$(MK_DIR)/%.mk: $(IMAGE_DIR)/add-%/Dockerfile
	@echo "Auto-generating Makefile $@:"
	@printf '# --- %s ADD-ON TARGETS ---\n\n' "$*" > $@.tmp

	@printf 'php-cli-%%-%s: php-cli-%% images/add-%s/Dockerfile\n' "$*" "$*" >> $@.tmp
	@printf '\t@echo "=== Building %s Add-on for php-cli:$$* ==="\n' "$*" >> $@.tmp
	@printf '\tdocker build \\\n' >> $@.tmp
	@printf '\t\t--build-arg BASE_IMAGE=php-cli:$$* \\\n' >> $@.tmp
	@printf '\t\t-t php-cli:$$*-$* \\\n' $* >> $@.tmp
	@printf '\t\timages/add-%s\n' "$*" >> $@.tmp
	@printf '\t@touch $$(BUILT_DIR)/$$@\n\n' >> $@.tmp

	@printf 'php-apache-%%-%s: php-apache-%% images/add-%s/Dockerfile\n' "$*" "$*" >> $@.tmp
	@printf '\t@echo "=== Building %s Add-on for php-apache:$$* ==="\n' "$*" >> $@.tmp
	@printf '\tdocker build \\\n' >> $@.tmp
	@printf '\t\t--build-arg BASE_IMAGE=php-apache:$$* \\\n' >> $@.tmp
	@printf '\t\t-t php-apache:$$*-$* \\\n' $* >> $@.tmp
	@printf '\t\timages/add-%s\n' "$*" >> $@.tmp
	@printf '\t@touch $$(BUILT_DIR)/$$@\n\n' >> $@.tmp

	@printf 'php-fpm-%%-%s: php-fpm-%% images/add-%s/Dockerfile\n' "$*" "$*" >> $@.tmp
	@printf '\t@echo "=== Building %s Add-on for php-fpm:$$* ==="\n' "$*" >> $@.tmp
	@printf '\tdocker build \\\n' >> $@.tmp
	@printf '\t\t--build-arg BASE_IMAGE=php-fpm:$$* \\\n' >> $@.tmp
	@printf '\t\t-t php-fpm:$$*-$* \\\n' $* >> $@.tmp
	@printf '\t\timages/add-%s\n' "$*" >> $@.tmp
	@printf '\t@touch $$(BUILT_DIR)/$$@\n\n' >> $@.tmp

	@mv $@.tmp $@

### not adding Oracle because I can't test it without an Oracle license:
# # --- ORACLE FILE DEPENDENCIES ---
# ORACLE_BASIC_ZIP := downloads/instantclient-basic-linux.x64-19.24.0.0.0dbru.zip
# ORACLE_SDK_ZIP   := downloads/instantclient-sdk-linux.x64-19.24.0.0.0dbru.zip

# # Rule triggered only when the required zip files are missing from downloads/
# $(ORACLE_BASIC_ZIP) $(ORACLE_SDK_ZIP):
# 	@echo "========================================================================="
# 	@echo "ERROR: Missing required Oracle Instant Client package: $@"
# 	@echo ""
# 	@echo "For Oracle licensing reasons, please manually download the following files"
# 	@echo "from the Oracle Technology Network (OTN) and place them in downloads/:"
# 	@echo "  1) $(notdir $(ORACLE_BASIC_ZIP))"
# 	@echo "  2) $(notdir $(ORACLE_SDK_ZIP))"
# 	@echo ""
# 	@echo "Download URL:"
# 	@echo "  https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html"
# 	@echo "========================================================================="
# 	@exit 1

# # --- oracle ADD-ON TARGETS ---
# # - uses context trick so ./downloads/ is available

# php-cli-%-oracle: php-cli-% $(ORACLE_BASIC_ZIP) $(ORACLE_SDK_ZIP)
# 	@echo "=== Building oracle Add-on for php-cli:$* ==="
# 	docker build \
# 		--build-arg BASE_IMAGE=php-cli:$* \
# 		-t php-cli:$*-oracle \
# 		-f $(IMAGE_DIR)/add-oracle/Dockerfile \
# 		./
# 	@touch $(BUILT_DIR)/$@

# php-apache-%-oracle: php-apache-% $(ORACLE_BASIC_ZIP) $(ORACLE_SDK_ZIP)
# 	@echo "=== Building oracle Add-on for php-apache:$* ==="
# 	docker build \
# 		--build-arg BASE_IMAGE=php-apache:$* \
# 		-t php-apache:$*-oracle \
# 		-f $(IMAGE_DIR)/add-oracle/Dockerfile \
# 		./
# 	@touch $(BUILT_DIR)/$@

# php-fpm-%-oracle: php-fpm-% $(ORACLE_BASIC_ZIP) $(ORACLE_SDK_ZIP)
# 	@echo "=== Building oracle Add-on for php-fpm:$* ==="
# 	docker build \
# 		--build-arg BASE_IMAGE=php-fpm:$* \
# 		-t php-fpm:$*-oracle \
# 		-f $(IMAGE_DIR)/add-oracle/Dockerfile \
# 		./
# 	@touch $(BUILT_DIR)/$@

# --- UTILITIES ---

list:
	@echo "Standard PHP Versions: $(MODERN_VERSIONS)"
	@echo "Legacy PHP Versions:   $(LEGACY_VERSIONS)"
	@echo "Standalone Images:     $(OTHER_IMAGES)"

list-detail:
	@echo "Generated Targets:"
	@for t in $(PHP_TARGETS); do echo "  - $$t"; done
	@echo "Generated Legacy Targets:"
	@for t in $(PHP_TARGETS); do echo "  - $$t"; done

list-tests:
	@echo "PHP Test Targets:   $(PHP_TEST_TARGETS)"
	@echo "Other Test Targets: $(OTHER_TEST_TARGETS)"

# --- TEST RULES ---
test: $(OTHER_TEST_TARGETS) $(PHP_TEST_TARGETS)
	@echo "=================================================="
	@echo "All health checks passed successfully!"
	@echo "=================================================="

test-cli: $(CLI_TEST_TARGETS)
	@echo "=================================================="
	@echo "All PHP CLI checks passed!"
	@echo "=================================================="

test-apache: $(APACHE_TEST_TARGETS)
	@echo "=================================================="
	@echo "All PHP Apache checks passed!"
	@echo "=================================================="

test-fpm: $(FPM_TEST_TARGETS)
	@echo "=================================================="
	@echo "All PHP FPM/FPM checks passed!"
	@echo "=================================================="

# --- SPECIFIC PHP TEST RULES FIRST ---
test-php-cli-%: $(BUILT_DIR)/php-cli-%
	@echo "Testing php-cli:$*..."
	@docker run --rm php-cli:$* php -v 2>&1 \
		| grep -q "PHP $*" || \
		(echo "  ✗ Test failed for php-cli:$*"; exit 1)
	@echo "  ✓ php-cli:$* reported correct version ($*)"

test-php-apache-%: $(BUILT_DIR)/php-apache-%
	@echo "Testing php-apache:$*..."
	@# Check PHP CLI version inside Apache container
	@docker run --rm php-apache:$* php -v 2>&1 \
		| grep -q "PHP $*" || \
		(echo "  ✗ PHP version test failed for php-apache:$*"; exit 1)
	@# Check Apache service
	@docker run --rm php-apache:$* apache2ctl -v 2>&1 \
		| grep -q "Apache" || \
		(echo "  ✗ Apache service check failed for php-apache:$*"; exit 1)
	@echo "  ✓ php-apache:$* Apache functional & reported PHP $*"

test-php-fpm-%: $(BUILT_DIR)/php-fpm-%
	@echo "Testing php-fpm:$*..."
	@# 1. PHP Version Sanity Check
	@# Check PHP version report inside container
	@docker run --rm php-fpm:$* php -v 2>&1 \
		| grep -q "PHP $*" || \
		(echo "  ✗ PHP version test failed for php-fpm:$*"; exit 1)
	@# 2. Check FPM config or FastCGI engine
	@# Test FPM config (APT versioned vs legacy unversioned) or FastCGI binary (5.0-5.2)
	@set -e ; \
	if docker run --rm php-fpm:$* which php-fpm$* >/dev/null 2>&1; then \
		docker run --rm php-fpm:$* php-fpm$* -t 2>&1 | grep -q "successful" || \
		(echo "  ✗ FPM config check failed for php-fpm:$*"; exit 1); \
	elif docker run --rm php-fpm:$* which php-fpm >/dev/null 2>&1; then \
		docker run --rm php-fpm:$* php-fpm -t 2>&1 | grep -q "successful" || \
		(echo "  ✗ FPM config check failed for php-fpm:$*"; exit 1); \
	else \
		docker run --rm php-fpm:$* php-cgi -v 2>&1 | grep -E -q "cgi-fcgi|PHP $*" || \
		(echo "  ✗ FastCGI check failed for php-fpm:$*"; exit 1); \
	fi
	@echo "  ✓ php-fpm:$* FPM/FastCGI valid & reported PHP $*"

# ==============================================================================
# Add-on Test Suite
# ==============================================================================

# Function to convert target name (php-cli-8.2-redis) to Docker image tag (php-cli:8.2-redis)
target_to_image = $(patsubst php-cli-%,php-cli:%,$(patsubst php-fpm-%,php-fpm:%,$(patsubst php-apache-%,php-apache:%,$(1))))
# # Function to convert image tags (php-cli:8.2-redis) to target names (php-cli-8.2-redis)
# image_to_target = $(subst :,-,$(1))

# Test targets covering 2-segment, 3-segment, single, and a 3-layer stacked add-on
TEST_ADDON_TARGETS := \
    php-cli-8.2-redis \
    php-fpm-7.4-memcached \
    php-apache-5.6.40-soap \
    php-apache-8.2-redis-pgsql-soap

# Dynamically derive image names for test-addon.sh
TEST_ADDON_IMAGES := $(call target_to_image,$(TEST_ADDON_TARGETS))

.PHONY: test-addons
test-addons: $(TEST_ADDON_TARGETS)
	@echo "==> Verifying extension loading across built add-on images..."
	@chmod +x stack_test/test-addon.sh
	@./stack_test/test-addon.sh $(TEST_ADDON_IMAGES)

# --- GENERIC STANDALONE TEST RULE LAST ---
# Using an explicit static pattern rule prevents it from stealing test-php-* targets:
$(OTHER_TEST_TARGETS): test-%: $(BUILT_DIR)/%
	@echo "Testing image: $*:latest..."
	@docker image inspect $*:latest > /dev/null 2>&1 \
		|| (echo "ERROR: Image $*:latest not found!"; exit 1)
	@echo "  ✓ $*:latest image exists."

.PHONY: test-stack

test-stack: all
	@chmod +x stack_test/test_all.sh
	@cd stack_test && ./test_all.sh

# --- DISK USAGE ---

.PHONY: disk-usage

# Displays disk space consumed by Docker system objects and project PHP images
disk-usage:
	@echo "=================================================="
	@echo "Docker System Overview"
	@echo "=================================================="
	@docker system df
	@echo ""
	@echo "=================================================="
	@echo "PHP Library Images Space"
	@echo "=================================================="
	@docker images "php-*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -V

# --- CLEAN ---

.PHONY: clean clean-downloads prune clean-cache clean-images clean-all

# Removes build markers, forcing Docker to re-run image build steps
clean:
	@echo "Clearing build flags..."
	rm -rf $(BUILT_DIR)
	@echo "Clean completed."

# Removes downloaded tarball archives
clean-downloads:
	@echo "Cleaning downloaded tarballs..."
	@rm -rf $(DOWNLOADS_DIR)
	@echo "Clean completed."

# Prunes dangling intermediate build stages and removes local state markers
prune:
	@echo "=================================================="
	@echo "Pruning dangling build stages & state markers..."
	@echo "=================================================="
	docker image prune -f --filter "dangling=true"
	@echo "Prune completed."

# Prunes unused Docker build cache (useful for freeing disk space after multi-stage builds)
clean-cache:
	@echo "=================================================="
	@echo "Pruning Docker build cache..."
	@echo "=================================================="
	docker builder prune -f

# Removes all generated php-* images created by this Makefile
clean-images:
	@echo "=================================================="
	@echo "Removing generated PHP Docker images..."
	@echo "=================================================="
	-docker images "php-*" -q | xargs -r docker rmi -f
	rm -rf $(BUILT_DIR)

# Complete reset: Cleans state markers, removes images, and purges build cache
clean-all: clean clean-downloads prune clean-cache clean-images
	@echo "Full cleanup finished."
