#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default command
CMD=${1:-"help"}

# Change to script directory
cd "${SCRIPT_DIR}"

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    echo "Please copy .env.example to .env and configure it"
    exit 1
fi

# Create required directories
setup() {
    mkdir -p "${RUNNER_WORK_DIR}" "${RUNNER_CONFIG_DIR}"
    echo "Created directories:"
    echo "  Work dir: ${RUNNER_WORK_DIR}"
    echo "  Config dir: ${RUNNER_CONFIG_DIR}"

    # Determine Docker socket path based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS Docker socket path
        DOCKER_SOCKET_PATH="${HOME}/.docker/run/docker.sock"
    else
        # Default Docker socket path for Linux
        DOCKER_SOCKET_PATH="/var/run/docker.sock"
    fi

    # Check if Docker socket exists and is a socket file
    if [ -S "${DOCKER_SOCKET_PATH}" ]; then
        # Get group ID and group name of the Docker socket
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS specific commands
            DOCKER_SOCKET_GROUP_ID=$(stat -f "%g" "${DOCKER_SOCKET_PATH}")
            DOCKER_SOCKET_GROUP_NAME=$(stat -f "%Sg" "${DOCKER_SOCKET_PATH}")
        else
            # Linux specific commands
            DOCKER_SOCKET_GROUP_ID=$(stat -c "%g" "${DOCKER_SOCKET_PATH}")
            DOCKER_SOCKET_GROUP_NAME=$(stat -c "%G" "${DOCKER_SOCKET_PATH}")
        fi

        # Ensure current user is in the Docker socket group
        if ! groups | grep -q "\b${DOCKER_SOCKET_GROUP_NAME}\b"; then
            echo "Warning: Current user is not in the Docker socket group (${DOCKER_SOCKET_GROUP_NAME})."
            exit 1
        fi

        # Export group ID for Docker Compose
        export DOCKER_GROUP_ID=$DOCKER_SOCKET_GROUP_ID
    else
        echo "Error: Docker socket not found at ${DOCKER_SOCKET_PATH}"
        exit 1
    fi
}

case $CMD in
    "up")
        setup
        docker compose up -d
        docker compose logs -f
        ;;
    "down")
        docker compose down
        ;;
    "logs")
        docker compose logs -f
        ;;
    "restart")
        docker compose restart
        docker compose logs -f
        ;;
    "update")
        docker compose pull
        docker compose up -d
        docker compose logs -f
        ;;
    *)
        echo "Usage: $0 <command>"
        echo "Commands:"
        echo "  up        Start the runner"
        echo "  down      Stop the runner"
        echo "  logs      View runner logs"
        echo "  restart   Restart the runner"
        echo "  update    Update runner image"
        exit 1
        ;;
esac