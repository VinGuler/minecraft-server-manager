#!/usr/bin/env bash

# start-world.sh - Start a Minecraft world
# Usage: ./scripts/start-world.sh [world_name]

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
echo -e "${BLUE}🚀 Start Minecraft World${NC}"
echo "========================"
echo ""

# Get world name
WORLD_NAME="$1"

if [ -z "$WORLD_NAME" ]; then
    # List available worlds
    echo "Available worlds:"
    for world_dir in "$WORLDS_DIR"/*/; do
        if [ -d "$world_dir" ] && [ -f "$world_dir/docker-compose.yml" ]; then
            world=$(basename "$world_dir")
            echo "  - $world"
        fi
    done
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
    echo -e "${RED}❌${NC} World '$WORLD_NAME' not found in $WORLDS_DIR/"
    exit 1
fi

if [ ! -f "$WORLD_DIR/docker-compose.yml" ]; then
    echo -e "${RED}❌${NC} No docker-compose.yml found for '$WORLD_NAME'"
    echo "Run ./scripts/create-world.sh to set it up"
    exit 1
fi

# Ensure data directory exists
mkdir -p "$WORLD_DIR/data"

# Copy shared config to world's data folder
echo -e "${BLUE}📋${NC} Loading shared config..."
"$SCRIPTS_DIR/load-configs.sh" "$WORLD_NAME"

# Start the container
echo ""
echo -e "${BLUE}🐳${NC} Starting Docker container..."
cd "$WORLD_DIR"
docker compose up -d

# Get port from docker-compose.yml
PORT=$(grep -oP "^\s*-\s*['\"]?\K\d+" docker-compose.yml 2>/dev/null | head -1)
[ -z "$PORT" ] && PORT="19132"

echo ""
echo -e "${GREEN}✅ World '$WORLD_NAME' started successfully!${NC}"
echo ""
echo "Connection info:"
echo "  Address: your-server-ip"
echo "  Port: $PORT"
echo ""
echo "Useful commands:"
echo "  View logs:  docker logs -f mc-$WORLD_NAME"
echo "  Console:    docker attach mc-$WORLD_NAME (Ctrl+P, Ctrl+Q to detach)"
echo "  Stop:       ./scripts/stop-world.sh $WORLD_NAME"
echo ""
