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
setup_dirs() {
    mkdir -p "${RUNNER_WORK_DIR}" "${RUNNER_CONFIG_DIR}"
    echo "Created directories:"
    echo "  Work dir: ${RUNNER_WORK_DIR}"
    echo "  Config dir: ${RUNNER_CONFIG_DIR}"
}

case $CMD in
    "up")
        setup_dirs
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