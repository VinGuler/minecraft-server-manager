#!/usr/bin/env bash

# stop-world.sh - Stop a Minecraft world
# Usage: ./scripts/stop-world.sh [world_name] [--backup]

set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORLDS_DIR="$BASE_DIR/worlds"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}🛑 Stop Minecraft World${NC}"
echo "======================="
echo ""

# Parse arguments
WORLD_NAME=""
CREATE_BACKUP=false

for arg in "$@"; do
    if [ "$arg" = "--backup" ] || [ "$arg" = "-b" ]; then
        CREATE_BACKUP=true
    elif [ -z "$WORLD_NAME" ]; then
        WORLD_NAME="$arg"
    fi
done

if [ -z "$WORLD_NAME" ]; then
    # List running worlds
    echo "Running worlds:"
    running_found=false
    for world_dir in "$WORLDS_DIR"/*/; do
        if [ -d "$world_dir" ]; then
            world=$(basename "$world_dir")
            container_name="mc-$world"
            if docker ps --filter "name=^${container_name}$" --format "{{.Names}}" 2>/dev/null | grep -q .; then
                echo "  - $world"
                running_found=true
            fi
        fi
    done

    if [ "$running_found" = false ]; then
        echo "  (none running)"
        echo ""
        exit 0
    fi

    echo ""
    read -p "Enter world name: " WORLD_NAME

    if [ -z "$WORLD_NAME" ]; then
        echo -e "${RED}❌${NC} No world name provided"
        exit 1
    fi
fi

WORLD_DIR="$WORLDS_DIR/$WORLD_NAME"

# Check if world exists
if [ ! -d "$WORLD_DIR" ]; then
    echo -e "${RED}❌${NC} World '$WORLD_NAME' not found"
    exit 1
fi

# Ask about backup if not specified
if [ "$CREATE_BACKUP" = false ]; then
    read -p "Create backup before stopping? [y/N]: " backup_choice
    if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
        CREATE_BACKUP=true
    fi
fi

# Create backup if requested
if [ "$CREATE_BACKUP" = true ]; then
    echo ""
    echo -e "${BLUE}💾${NC} Creating backup..."
    "$SCRIPTS_DIR/backup-world.sh" "$WORLD_NAME"
fi

# Stop the container
echo ""
echo -e "${BLUE}🐳${NC} Stopping Docker container..."
cd "$WORLD_DIR"
docker compose down

echo ""
echo -e "${GREEN}✅ World '$WORLD_NAME' stopped successfully!${NC}"
echo ""
