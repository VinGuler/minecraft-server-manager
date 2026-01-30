#!/usr/bin/env bash

# backup-worlds.sh - Backup ALL worlds
# Usage: ./scripts/backup-worlds.sh

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
echo -e "${BLUE}💾 Backup All Minecraft Worlds${NC}"
echo "=============================="
echo ""

if [ ! -d "$WORLDS_DIR" ]; then
    echo -e "${YELLOW}⚠️${NC} No worlds directory found"
    exit 0
fi

# Count worlds with data
world_count=0
for world_dir in "$WORLDS_DIR"/*/; do
    if [ -d "$world_dir/data" ]; then
        ((world_count++)) || true
    fi
done

if [ "$world_count" -eq 0 ]; then
    echo -e "${YELLOW}⚠️${NC} No worlds with data found"
    exit 0
fi

echo "Found $world_count world(s) to backup"
echo ""

# Backup each world
success_count=0
fail_count=0

for world_dir in "$WORLDS_DIR"/*/; do
    if [ -d "$world_dir/data" ]; then
        world=$(basename "$world_dir")
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Backing up: $world"
        echo ""

        if "$SCRIPTS_DIR/backup-world.sh" "$world"; then
            ((success_count++)) || true
        else
            ((fail_count++)) || true
            echo -e "${RED}❌${NC} Failed to backup $world"
        fi
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Backup complete!${NC}"
echo "   Successful: $success_count"
if [ "$fail_count" -gt 0 ]; then
    echo -e "   ${RED}Failed: $fail_count${NC}"
fi
echo ""
echo "Backups stored in: ~/backups/"
echo ""
