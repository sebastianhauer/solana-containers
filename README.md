# Solana Container Build

A multi-architecture Docker container build system for Solana nodes with integrated
GitHub Actions CI/CD pipeline and efficient caching strategies.

## Features

- 🏗️ Multi-architecture support (x86_64/ARM64)
- 🚀 Optimized multi-stage builds
- 📦 Registry-based caching in CI
- 💻 Local filesystem caching for development
- 🔄 Automated weekly builds via GitHub Actions

## Quick Start

1. Build for your local architecture:

```shell
make build
```

2. Build for a specific architecture:

```shell
make build-amd64  # or build-arm64
```

3. Test the build:

```shell
make test
```

## Build Configuration

Environment variables that can be set:

- `PLATFORM`: Build platform (linux/amd64 or linux/arm64)
- `CONTAINER_REGISTRY`: Container registry path
- `DISTRO`: Base distribution (default: debian)
- `DISTRO_RELEASE`: Distribution version (default: bullseye)
- `DISTRO_VARIANT`: Distribution variant (default: slim)

## Build Process Details

> 🔍 **Understanding the Build Process**
>
> ### Builder Stage
> ```shell
> make build-builder
> ```
> Builds the builder image with Rust and Solana build dependencies
>
> ### Runtime Stage
> ```shell
> make build-runtime
> ```
> Creates the minimal runtime image from the builder stage
>
> ### Cache Strategy
> - CI: Uses registry-based caching
> - Local: Uses filesystem-based caching

## Available Make Targets

- `build`: Build all stages
- `build-builder`: Build only the builder stage
- `build-runtime`: Build only the runtime stage
- `test`: Test the built image
- `clean`: Clean up Docker resources
- `config`: Show current build configuration
- `cache-info`: Display cache information

## GitHub Actions Workflow

The project includes automated builds that:
- Run monthly
- Support manual triggering
- Build for multiple architectures
- Clean up old container images

## Self-Hosted ARM64 Runner

To support ARM64 builds in our CI pipeline, we maintain a self-hosted GitHub Actions runner. While GitHub-hosted runners handle the AMD64 builds, we use our own ARM64 runner to ensure proper multi-architecture support. For details on setting up and managing the runner, see our [self-hosted runner documentation](.github/runner/self-hosted-github-runner.md).

## Available Docker Images

Pre-built Docker images are available from the GitHub Container Registry for both x86_64 (AMD64) and ARM64 architectures:

```shell
# Pull the latest image (Docker will automatically select the correct architecture)
docker pull ghcr.io/sebastianhauer/solana-containers/solana:latest-debian-bullseye

# Explicitly pull for a specific architecture
docker pull --platform linux/amd64 ghcr.io/sebastianhauer/solana-containers/solana:latest-debian-bullseye
docker pull --platform linux/arm64 ghcr.io/sebastianhauer/solana-containers/solana:latest-debian-bullseye
```

Available variants:
- `latest-debian-bullseye`: Full Debian Bullseye-based image
- `latest-debian-bullseye-slim`: Minimal Debian Bullseye-based image

All variants are built for both x86_64 and ARM64 architectures, making them suitable for:
- Standard x86_64 servers and cloud instances
- ARM64-based servers (e.g., AWS Graviton, Apple Silicon Macs)

View all available tags and versions in the [GitHub Container Registry](https://github.com/sebastianhauer/solana-containers/pkgs/container/solana-containers%2Fsolana).


## Additional Resources

- [Solana Documentation](https://docs.solana.com/)
