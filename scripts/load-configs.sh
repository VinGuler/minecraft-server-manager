#!/usr/bin/env bash

# load-configs.sh - Copy shared config to world(s)
# Usage: ./scripts/load-configs.sh [world_name]
# If no world specified, copies to ALL worlds

set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$BASE_DIR/config"
WORLDS_DIR="$BASE_DIR/worlds"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

copy_config_to_world() {
    local world="$1"
    local data_dir="$WORLDS_DIR/$world/data"

    # Ensure data directory exists
    mkdir -p "$data_dir"

    # Copy config files
    if [ -f "$CONFIG_DIR/permissions.json" ]; then
        cp "$CONFIG_DIR/permissions.json" "$data_dir/"
    fi

    if [ -f "$CONFIG_DIR/server.properties" ]; then
        cp "$CONFIG_DIR/server.properties" "$data_dir/"
    fi

    echo -e "${GREEN}✅${NC} Config copied to $world"
}

echo ""
echo "📋 Loading Shared Config"
echo "========================"
echo ""

if [ -n "$1" ]; then
    # Single world specified
    if [ ! -d "$WORLDS_DIR/$1" ]; then
        echo -e "${YELLOW}⚠️${NC} World '$1' not found"
        exit 1
    fi
    copy_config_to_world "$1"
else
    # Copy to all worlds
    echo "Copying config to all worlds..."
    echo ""

    for world_dir in "$WORLDS_DIR"/*/; do
        if [ -d "$world_dir" ]; then
            world=$(basename "$world_dir")
            copy_config_to_world "$world"
        fi
    done
fi

echo ""
echo "Done!"
