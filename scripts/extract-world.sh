#!/usr/bin/env bash

# extract-world.sh - Extract an uploaded .mcworld file
# Usage: ./scripts/extract-world.sh [world_name] [level_name]

set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORLDS_DIR="$BASE_DIR/worlds"
UPLOADS_DIR="$BASE_DIR/uploads"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}📦 Extract Minecraft World${NC}"
echo "=========================="
echo ""

# Check uploads directory
if [ ! -d "$UPLOADS_DIR" ]; then
    mkdir -p "$UPLOADS_DIR"
fi

# List available uploads
echo "Available uploads:"
uploads_found=false
for file in "$UPLOADS_DIR"/*.mcworld; do
    if [ -f "$file" ]; then
        echo "  - $(basename "$file")"
        uploads_found=true
    fi
done

if [ "$uploads_found" = false ]; then
    echo "  (none found)"
    echo ""
    echo "Upload a .mcworld file first using:"
    echo "  Windows: .\\scripts\\upload-world.ps1"
    echo ""
    exit 1
fi

echo ""

# Get world name
WORLD_NAME="$1"
if [ -z "$WORLD_NAME" ]; then
    read -p "Enter world name (folder name, lowercase): " WORLD_NAME
fi

if [ -z "$WORLD_NAME" ]; then
    echo -e "${RED}❌${NC} World name cannot be empty"
    exit 1
fi

# Validate world name (POSIX-compatible)
case "$WORLD_NAME" in
    *[!a-z0-9_-]* | "")
        echo -e "${RED}❌${NC} World name must be lowercase letters, numbers, hyphens, or underscores only"
        exit 1
        ;;
esac

# Check for .mcworld file
MCWORLD_FILE="$UPLOADS_DIR/${WORLD_NAME}.mcworld"
if [ ! -f "$MCWORLD_FILE" ]; then
    # Try to find any matching file
    echo -e "${YELLOW}⚠️${NC} File '${WORLD_NAME}.mcworld' not found in uploads/"
    echo ""
    read -p "Enter the exact filename (without .mcworld): " UPLOAD_NAME
    MCWORLD_FILE="$UPLOADS_DIR/${UPLOAD_NAME}.mcworld"

    if [ ! -f "$MCWORLD_FILE" ]; then
        echo -e "${RED}❌${NC} File not found: $MCWORLD_FILE"
        exit 1
    fi
fi

# Get LEVEL_NAME
LEVEL_NAME="$2"
if [ -z "$LEVEL_NAME" ]; then
    echo ""
    read -p "Enter LEVEL_NAME (in-game world name): " LEVEL_NAME
fi

if [ -z "$LEVEL_NAME" ]; then
    LEVEL_NAME="$WORLD_NAME"
    echo "Using default: $LEVEL_NAME"
fi

WORLD_DIR="$WORLDS_DIR/$WORLD_NAME"
DATA_DIR="$WORLD_DIR/data"
WORLDS_DATA_DIR="$DATA_DIR/worlds/$LEVEL_NAME"

# Check if world exists, if not create it
if [ ! -f "$WORLD_DIR/docker-compose.yml" ]; then
    echo ""
    echo -e "${BLUE}🌍${NC} World config not found. Creating new world..."
    echo ""

    read -p "Enter SERVER_NAME (shows in server list): " SERVER_NAME
    if [ -z "$SERVER_NAME" ]; then
        SERVER_NAME="$LEVEL_NAME Server"
    fi

    read -p "Enter port [19132]: " PORT
    if [ -z "$PORT" ]; then
        PORT="19132"
    fi

    mkdir -p "$WORLD_DIR"

    cat > "$WORLD_DIR/docker-compose.yml" << EOF
services:
  minecraft:
    build: ../..
    container_name: mc-${WORLD_NAME}
    ports:
      - "${PORT}:19132/udp"
    environment:
      EULA: "TRUE"
      LEVEL_NAME: "${LEVEL_NAME}"
      SERVER_NAME: "${SERVER_NAME}"
      MAX_PLAYERS: "10"
    volumes:
      - ./data:/data
    restart: unless-stopped
    stdin_open: true
    tty: true
EOF

    echo -e "${GREEN}✅${NC} Docker config created"
fi

# Create data directory structure
echo ""
echo -e "${BLUE}📁${NC} Creating directory structure..."
mkdir -p "$WORLDS_DATA_DIR"

# Extract .mcworld (it's a zip file)
echo -e "${BLUE}📦${NC} Extracting world data..."
unzip -o "$MCWORLD_FILE" -d "$WORLDS_DATA_DIR"

# Copy shared config
echo -e "${BLUE}📋${NC} Copying shared config..."
"$SCRIPTS_DIR/load-configs.sh" "$WORLD_NAME"

# Clean up upload file
echo -e "${BLUE}🗑️${NC} Cleaning up upload file..."
rm -f "$MCWORLD_FILE"

echo ""
echo -e "${GREEN}✅ World extracted successfully!${NC}"
echo ""
echo "World location: worlds/$WORLD_NAME/data/worlds/$LEVEL_NAME/"
echo ""
echo "Next steps:"
echo "  Start the world:  ./scripts/start-world.sh $WORLD_NAME"
echo ""
