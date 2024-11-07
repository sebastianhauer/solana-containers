ARG VARIANT=bullseye
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

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
    zsh \
    vim-nox \
    emacs-nox \
    ripgrep \
    && apt-get autoremove --quiet --quiet --yes \
    && apt-get clean --quiet --quiet \
    && rm --recursive --force /var/lib/apt/lists/* \
    && rm --recursive --force /tmp/* /var/tmp/*

