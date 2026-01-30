#!/usr/bin/env bash

# backup-world.sh - Backup a single world
# Usage: ./scripts/backup-world.sh [world_name]

set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORLDS_DIR="$BASE_DIR/worlds"
BACKUP_BASE="$HOME/backups"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get world name
WORLD_NAME="$1"

if [ -z "$WORLD_NAME" ]; then
    echo ""
    echo -e "${BLUE}💾 Backup Minecraft World${NC}"
    echo "========================="
    echo ""

    # List available worlds
    echo "Available worlds:"
    for world_dir in "$WORLDS_DIR"/*/; do
        if [ -d "$world_dir/data" ]; then
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
DATA_DIR="$WORLD_DIR/data"
BACKUP_DIR="$BACKUP_BASE/$WORLD_NAME"
CONTAINER_NAME="mc-${WORLD_NAME}"

# Check if world data exists
if [ ! -d "$DATA_DIR" ]; then
    echo -e "${RED}❌${NC} No data found for world '$WORLD_NAME'"
    exit 1
fi

# Check if container is running - warn about potential data inconsistency
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}⚠️  WARNING: Container '$CONTAINER_NAME' is running${NC}"
    echo -e "${YELLOW}   For a consistent backup, stop the server first:${NC}"
    echo -e "${YELLOW}   ./scripts/stop-world.sh $WORLD_NAME${NC}"
    echo ""
    read -p "Continue with backup anyway? [y/N]: " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Backup cancelled."
        exit 0
    fi
fi

# Date + unique 4-char code
DATE_STR=$(date +"%Y-%m-%d")
UNIQUE_CODE=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)

# Backup file
BACKUP_NAME="${DATE_STR}__backup__${UNIQUE_CODE}.zip"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Maintain max 3 backups per world (delete oldest if needed)
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
while [ "$BACKUP_COUNT" -ge 3 ]; do
    OLDEST_BACKUP=$(ls -1t "$BACKUP_DIR" | tail -1)
    rm -f "$BACKUP_DIR/$OLDEST_BACKUP"
    echo -e "${YELLOW}🗑️${NC} Deleted oldest backup: $OLDEST_BACKUP"
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
done

# Create backup - full data directory including symlinks and all files
echo -e "${BLUE}📦${NC} Creating backup for '$WORLD_NAME'..."
cd "$WORLD_DIR"

# -r: recursive, -y: store symlinks, -q: quiet
# This backs up the ENTIRE data directory including:
# - worlds/<level_name>/db/ (LevelDB with player data, chunks, etc.)
# - worlds/<level_name>/level.dat (world metadata)
# - permissions.json, allowlist.json, server.properties, etc.
zip -ryq "$BACKUP_PATH" "data"

# Verify backup was created and show size
if [ -f "$BACKUP_PATH" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    FILE_COUNT=$(unzip -l "$BACKUP_PATH" 2>/dev/null | tail -1 | awk '{print $2}')
    echo -e "${GREEN}✅${NC} Backup created: $BACKUP_PATH"
    echo -e "   Size: $BACKUP_SIZE, Files: $FILE_COUNT"
    echo ""
    echo "To restore this backup:"
    echo "  1. Stop the world: ./scripts/stop-world.sh $WORLD_NAME"
    echo "  2. Extract backup: cd worlds/$WORLD_NAME && unzip -o $BACKUP_PATH"
    echo "  3. Start the world: ./scripts/start-world.sh $WORLD_NAME"
else
    echo -e "${RED}❌${NC} Backup failed - file not created"
    exit 1
fi
