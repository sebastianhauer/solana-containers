ARG DISTRO=debian
ARG DISTRO_RELEASE=bullseye
ARG DISTRO_VARIANT=slim
ARG RUST_VERSION=1.82
ARG SOLANA_VERSION

# Conditionally include dash only when VARIANT is set
ARG DISTRO_VARIANT_TAG=${DISTRO_VARIANT:+-${DISTRO_VARIANT}}

FROM rust:${RUST_VERSION}-slim-${DISTRO_RELEASE} AS builder

# System Update
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update --quiet --quiet \
    && apt-get upgrade --quiet --quiet --yes --no-install-recommends \
    && apt-get autoremove --quiet --quiet --yes \
    && apt-get clean --quiet --quiet \
    && rm --recursive --force /var/lib/apt/lists/* \
    && rm --recursive --force /tmp/* /var/tmp/*

# Additional Libraries & Tools
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update --quiet --quiet \
    && apt-get install --quiet --quiet --yes --no-install-recommends \
    jq \
    curl \
    libudev-dev \
    libclang-dev \
    libssl-dev \
    pkgconf \
    build-essential \
    g++ \
    cpp \
    protobuf-compiler \
    && apt-get autoremove --quiet --quiet --yes \
    && apt-get clean --quiet --quiet \
    && rm --recursive --force /var/lib/apt/lists/* \
    && rm --recursive --force /tmp/* /var/tmp/*

WORKDIR /src

# Use provided SOLANA_VERSION or fetch latest
RUN if [ -z "${SOLANA_VERSION}" ]; then \
        SOLANA_VERSION=$(curl --silent https://api.github.com/repos/solana-labs/solana/releases/latest | jq .tag_name --raw-output | sed 's/^v//'); \
    fi \
    && echo "Building Solana version: ${SOLANA_VERSION} on $(nproc) cores ..." \
    && curl --fail --silent --show-error --location \
        https://github.com/solana-labs/solana/archive/refs/tags/v${SOLANA_VERSION}.tar.gz \
        --output solana-${SOLANA_VERSION}.tar.gz \
    && tar --extract --gunzip --file solana-${SOLANA_VERSION}.tar.gz \
    && rm solana-${SOLANA_VERSION}.tar.gz \
    && cd solana-${SOLANA_VERSION} \
    && CARGO_BUILD_JOBS=$(nproc) \
       RUSTC_PARALLEL_COMPILER=true \
       RUST_STABLE_VERSION=${RUST_VERSION} \
       scripts/cargo-install-all.sh /usr/local/solana \
    && cd .. \
    && rm --recursive --force solana-${SOLANA_VERSION}

# Use the conditional tag
FROM ${DISTRO}:${DISTRO_RELEASE}${DISTRO_VARIANT_TAG} AS runtime

COPY --from=builder /usr/local/solana /usr/local/solana

RUN echo "export PATH=/usr/local/solana/bin:\$PATH" > /etc/profile.d/solana.sh \
    && chmod +x /etc/profile.d/solana.sh
