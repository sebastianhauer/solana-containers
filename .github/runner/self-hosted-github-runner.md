# GitHub Actions Self-Hosted Runner

This directory contains configuration for running a self-hosted GitHub Actions runner using Docker. The runner is specifically configured for ARM64 architecture and includes Docker-in-Docker support, making it suitable for container builds on ARM64 platforms like Apple Silicon Macs or ARM-based servers.

## Prerequisites

- Docker and Docker Compose installed
- Access to a GitHub repository with admin permissions
- ARM64-based system (e.g., Apple Silicon Mac, ARM server)

## Additional Resources

- [GitHub Actions Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker-in-Docker Documentation](https://docs.docker.com/engine/security/rootless/)
- [Runner Security Guidelines](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Actions Runner Controller (ARC)](https://github.com/actions/actions-runner-controller) - We are using this docker image for the runner: [summerwind/actions-runner-dind:ubuntu-22.04](https://hub.docker.com/r/summerwind/actions-runner-dind/tags)