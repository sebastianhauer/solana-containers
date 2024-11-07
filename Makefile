CONTAINER_REGISTRY ?= ghcr.io/sebastianhauer/solana-containers
PLATFORMS ?= linux/amd64,linux/arm64

DISTRO ?= debian
DISTRO_RELEASE ?= bullseye
DISTRO_VARIANT ?= slim
distro_variant_tag := $(DISTRO_VARIANT:%=-%)

SOLANA_VERSION ?= $(shell curl --silent https://api.github.com/repos/solana-labs/solana/releases/latest | jq .tag_name --raw-output | sed 's/^v//')
rust_version := $(shell curl --silent "https://raw.githubusercontent.com/solana-labs/solana/v$(SOLANA_VERSION)/rust-toolchain.toml" | grep channel | cut --delimiter='"' --fields=2)

.PHONY: build
build:
	docker buildx build \
		--builder multiarch-builder \
		--platform $(PLATFORMS) \
		--build-arg DISTRO=$(DISTRO) \
		--build-arg DISTRO_RELEASE=$(DISTRO_RELEASE) \
		--build-arg DISTRO_VARIANT=$(DISTRO_VARIANT) \
		--build-arg RUST_VERSION=$(rust_version) \
		--build-arg SOLANA_VERSION=$(SOLANA_VERSION) \
		--tag $(CONTAINER_REGISTRY)/solana:$(SOLANA_VERSION)-$(DISTRO)-$(DISTRO_RELEASE)$(distro_variant_tag) \
		--file containers/$(DISTRO).Dockerfile \
		--progress=plain \
		$(if $(CI),--push,--load) \
		containers


# Local development helpers
.PHONY: buildx-setup
buildx-setup:
	docker buildx create --name multiarch-builder --platform $(PLATFORMS) || true