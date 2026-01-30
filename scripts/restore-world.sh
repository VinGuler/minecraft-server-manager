#!/usr/bin/env bash

# restore-world.sh - Restore a world from backup
# Usage: ./scripts/restore-world.sh [world_name] [backup_file]

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

echo ""
echo -e "${BLUE}🔄 Restore Minecraft World${NC}"
echo "=========================="
echo ""

# Get world name
WORLD_NAME="$1"

if [ -z "$WORLD_NAME" ]; then
    # List available worlds with backups
    echo "Available worlds with backups:"
    for backup_dir in "$BACKUP_BASE"/*/; do
        if [ -d "$backup_dir" ]; then
            world=$(basename "$backup_dir")
            backup_count=$(ls -1 "$backup_dir"/*.zip 2>/dev/null | wc -l)
            if [ "$backup_count" -gt 0 ]; then
                echo "  - $world ($backup_count backups)"
            fi
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
BACKUP_DIR="$BACKUP_BASE/$WORLD_NAME"
CONTAINER_NAME="mc-${WORLD_NAME}"

# Check if backups exist
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    echo -e "${RED}❌${NC} No backups found for world '$WORLD_NAME'"
    exit 1
fi

# Get backup file
BACKUP_FILE="$2"

if [ -z "$BACKUP_FILE" ]; then
    echo ""
    echo "Available backups (newest first):"
    i=1
    declare -a backups
    for backup in $(ls -1t "$BACKUP_DIR"/*.zip 2>/dev/null); do
        backup_name=$(basename "$backup")
        backup_size=$(du -h "$backup" | cut -f1)
        echo "  $i) $backup_name ($backup_size)"
        backups[$i]="$backup"
        ((i++))
    done
    echo ""
    read -p "Select backup number [1]: " BACKUP_NUM

    if [ -z "$BACKUP_NUM" ]; then
        BACKUP_NUM=1
    fi

    BACKUP_FILE="${backups[$BACKUP_NUM]}"

    if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}❌${NC} Invalid selection"
        exit 1
    fi
else
    # If just a filename was provided, look in the backup dir
    if [ ! -f "$BACKUP_FILE" ]; then
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    fi
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}❌${NC} Backup file not found: $BACKUP_FILE"
        exit 1
    fi
fi

echo ""
echo "Selected: $(basename "$BACKUP_FILE")"

# Check if container is running
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo ""
    echo -e "${YELLOW}⚠️  Container '$CONTAINER_NAME' is running${NC}"
    read -p "Stop container and proceed with restore? [y/N]: " STOP_CONTAINER
    if [[ ! "$STOP_CONTAINER" =~ ^[Yy]$ ]]; then
        echo "Restore cancelled."
        exit 0
    fi
    echo ""
    echo -e "${BLUE}🛑${NC} Stopping container..."
    docker stop "$CONTAINER_NAME"
fi

# Confirm restore
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will replace all current data for '$WORLD_NAME'${NC}"
read -p "Are you sure you want to restore? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Create world directory if it doesn't exist
mkdir -p "$WORLD_DIR"

# Remove existing data
if [ -d "$WORLD_DIR/data" ]; then
    echo ""
    echo -e "${BLUE}🗑️${NC} Removing existing data..."
    rm -rf "$WORLD_DIR/data"
fi

# Extract backup
echo -e "${BLUE}📦${NC} Extracting backup..."
cd "$WORLD_DIR"
unzip -q "$BACKUP_FILE"

# Verify restore
if [ -d "$WORLD_DIR/data" ]; then
    echo ""
    echo -e "${GREEN}✅ Restore complete!${NC}"
    echo ""
    echo "Start the world with:"
    echo "  ./scripts/start-world.sh $WORLD_NAME"
else
    echo -e "${RED}❌${NC} Restore failed - data directory not found after extraction"
    exit 1
fi
