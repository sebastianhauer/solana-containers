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
- Run weekly on Thursday at 02:00 UTC
- Support manual triggering
- Build for multiple architectures
- Clean up old container images

## Additional Resources

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Solana Documentation](https://docs.solana.com/)
