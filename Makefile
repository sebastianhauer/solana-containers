# Host system detection
host_os := $(shell uname -s | tr '[:upper:]' '[:lower:]')
host_arch := $(shell uname -m)

# Map architecture to Docker-compatible architecture names
ifeq ($(host_arch),x86_64)
    docker_arch := amd64
else ifeq ($(host_arch),aarch64)
    docker_arch := arm64
else ifeq ($(host_arch),arm64)
    docker_arch := arm64
else
    $(error Unsupported architecture: $(host_arch))
endif

# Default platform configuration based on OS
ifeq ($(host_os),linux)
    default_platform := linux/$(docker_arch)
else ifeq ($(host_os),darwin)
    default_platform := linux/$(docker_arch)
else
    $(warning Unsupported host OS: $(host_os), defaulting to linux/amd64)
    default_platform := linux/amd64
endif

# User-configurable variables (uppercase)
PLATFORM ?= $(default_platform)
CONTAINER_REGISTRY ?= ghcr.io/sebastianhauer/solana-containers
DISTRO ?= debian
DISTRO_RELEASE ?= bullseye
DISTRO_VARIANT ?= slim

# Internal variables (lowercase)
supported_platforms := linux/amd64 linux/arm64
distro_variant_tag := $(DISTRO_VARIANT:%=-%)
build_start := $(shell date +%s)
time_elapsed = $(shell echo $$(($$(date +%s) - $(build_start))))

# Version detection
SOLANA_VERSION ?= $(shell curl --silent https://api.github.com/repos/solana-labs/solana/releases/latest | jq .tag_name --raw-output | sed 's/^v//')
rust_version := $(shell curl --silent "https://raw.githubusercontent.com/solana-labs/solana/v$(SOLANA_VERSION)/rust-toolchain.toml" | grep channel | cut --delimiter='"' --fields=2)

# Validate platform
ifeq ($(filter $(PLATFORM),$(supported_platforms)),)
    $(error Unsupported platform: $(PLATFORM). Supported platforms: $(supported_platforms))
endif

# Common build arguments
common_build_args = \
	--build-arg DISTRO=$(DISTRO) \
	--build-arg DISTRO_RELEASE=$(DISTRO_RELEASE) \
	--build-arg DISTRO_VARIANT=$(DISTRO_VARIANT) \
	--build-arg RUST_VERSION=$(rust_version) \
	--build-arg SOLANA_VERSION=$(SOLANA_VERSION)

# Target image tags (platform-specific for builder cache, unified for runtime)
builder_tag = $(CONTAINER_REGISTRY)/builder:cache-$(subst /,-,$(PLATFORM))
runtime_tag = $(CONTAINER_REGISTRY)/solana:$(SOLANA_VERSION)-$(DISTRO)-$(DISTRO_RELEASE)$(distro_variant_tag)
latest_tag = $(CONTAINER_REGISTRY)/solana:latest-$(DISTRO)-$(DISTRO_RELEASE)$(distro_variant_tag)

# Add conditional tag argument
runtime_tags = \
	--tag $(runtime_tag) \
	$(if $(CI),--tag $(latest_tag))

# Buildx configuration
buildx_args = \
	--progress=plain \
	$(if $(CI),--push,--load)

# Cache configuration
BUILDX_CACHE_PATH ?= /tmp/.buildx-cache

# Define comma for proper escaping
comma := ,

cache_args = $(if $(CI),\
    --cache-from type=registry$(comma)ref=$(builder_tag) \
    --cache-to type=registry$(comma)ref=$(builder_tag)$(comma)mode=max,\
    --cache-from type=local$(comma)src=$(BUILDX_CACHE_PATH) \
    --cache-to type=local$(comma)dest=$(BUILDX_CACHE_PATH)$(comma)mode=max)

# Print build info
define print_build_info
	@echo "→ Build Info:"
	@echo "  Registry:    $(CONTAINER_REGISTRY)"
	@echo "  Platform:    $(PLATFORM)"
	@echo "  Distro:      $(DISTRO):$(DISTRO_RELEASE)$(distro_variant_tag)"
	@echo "  Solana:      $(SOLANA_VERSION)"
	@echo "  Rust:        $(rust_version)"
	@echo "  Time:        $$(date)"
endef

# Print elapsed time
define print_elapsed_time
	@echo "→ Build completed in $(call time_elapsed) seconds"
endef

.PHONY: all
all: build-all

# Build builder stage with caching
.PHONY: build-builder
build-builder:
	$(call print_build_info)
	@echo "→ Building builder stage..."
	@mkdir -p $(BUILDX_CACHE_PATH)
	docker buildx build \
		$(buildx_args) \
		$(common_build_args) \
		--platform $(PLATFORM) \
		--target builder \
		--tag $(builder_tag) \
		$(cache_args) \
		--file containers/$(DISTRO).Dockerfile \
		containers
	$(call print_elapsed_time)

# Build runtime with cached builder
.PHONY: build-runtime
build-runtime:
	$(call print_build_info)
	@echo "→ Building runtime stage..."
	@mkdir -p $(BUILDX_CACHE_PATH)
	docker buildx build \
		$(buildx_args) \
		$(common_build_args) \
		--platform $(PLATFORM) \
		$(runtime_tags) \
		$(cache_args) \
		--file containers/$(DISTRO).Dockerfile \
		containers
	$(call print_elapsed_time)

# Build all stages
.PHONY: build-all
build-all: build-builder build-runtime

# Test built image
.PHONY: test
test:
	@echo "→ Testing image..."
	@docker run --rm $(runtime_tag) solana --version
	@echo "→ Test completed"

# Clean up
.PHONY: clean
clean:
	@echo "→ Cleaning up..."
	docker buildx rm multiarch-builder || true
	docker system prune -f
	@echo "→ Cleanup completed"

# Build specific architectures
.PHONY: build-amd64
build-amd64:
	@$(MAKE) build-all PLATFORM=linux/amd64

.PHONY: build-arm64
build-arm64:
	@$(MAKE) build-all PLATFORM=linux/arm64

# Print cache info
.PHONY: cache-info
cache-info:
	@echo "→ Cache Info:"
	@docker buildx du
	@echo "→ Builder Cache:"
	@docker buildx prune --filter type=regular --force --verbose

# Build with timing information
.PHONY: build
build:
	@echo "→ Starting build at $$(date)"
	@$(MAKE) build-all
	@echo "→ Build completed at $$(date)"
	@echo "→ Total build time: $(call time_elapsed) seconds"

# Development helper to watch logs
.PHONY: logs
logs:
	@docker buildx logs multiarch-builder --follow

# Matrix build helper
.PHONY: matrix-build
matrix-build:
	@for variant in "" slim; do \
		echo "Building variant: $$variant"; \
		$(MAKE) build DISTRO_VARIANT=$$variant; \
	done

# Show build configuration
.PHONY: config
config:
	$(call print_build_info)
