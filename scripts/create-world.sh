#!/usr/bin/env bash

# create-world.sh - Create a new world configuration
# Usage: ./scripts/create-world.sh

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
echo -e "${BLUE}🌍 Create New Minecraft World${NC}"
echo "=============================="
echo ""

# Get world name
read -p "Enter world name (folder name, lowercase, no spaces): " WORLD_NAME

if [ -z "$WORLD_NAME" ]; then
    echo -e "${RED}❌${NC} World name cannot be empty"
    exit 1
fi

# Validate world name (lowercase, no spaces)
if [[ ! "$WORLD_NAME" =~ ^[a-z0-9_-]+$ ]]; then
    echo -e "${RED}❌${NC} World name must be lowercase letters, numbers, hyphens, or underscores only"
    exit 1
fi

WORLD_DIR="$WORLDS_DIR/$WORLD_NAME"

# Check if world already exists
if [ -d "$WORLD_DIR" ]; then
    echo -e "${YELLOW}⚠️${NC} World '$WORLD_NAME' already exists"
    read -p "Overwrite docker-compose.yml? [y/N]: " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        exit 0
    fi
fi

# Get LEVEL_NAME
echo ""
read -p "Enter LEVEL_NAME (in-game world name, can have spaces): " LEVEL_NAME
if [ -z "$LEVEL_NAME" ]; then
    LEVEL_NAME="$WORLD_NAME"
    echo "Using default: $LEVEL_NAME"
fi

# Get SERVER_NAME
echo ""
read -p "Enter SERVER_NAME (shows in server list): " SERVER_NAME
if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="$LEVEL_NAME Server"
    echo "Using default: $SERVER_NAME"
fi

# Get port
echo ""
read -p "Enter port [19132]: " PORT
if [ -z "$PORT" ]; then
    PORT="19132"
fi

# Validate port
if [[ ! "$PORT" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌${NC} Port must be a number"
    exit 1
fi

# Check for port conflicts
echo ""
echo -e "${BLUE}📋${NC} Checking for port conflicts..."
for world_dir in "$WORLDS_DIR"/*/; do
    if [ -d "$world_dir" ] && [ -f "$world_dir/docker-compose.yml" ]; then
        other_world=$(basename "$world_dir")
        if [ "$other_world" != "$WORLD_NAME" ]; then
            other_port=$(grep -oP "^\s*-\s*['\"]?\K\d+" "$world_dir/docker-compose.yml" 2>/dev/null | head -1)
            if [ "$other_port" = "$PORT" ]; then
                echo -e "${YELLOW}⚠️${NC} Warning: Port $PORT is already used by '$other_world'"
                read -p "Continue anyway? [y/N]: " continue_anyway
                if [ "$continue_anyway" != "y" ] && [ "$continue_anyway" != "Y" ]; then
                    exit 0
                fi
            fi
        fi
    fi
done

# Create world directory
echo ""
echo -e "${BLUE}📁${NC} Creating world directory..."
mkdir -p "$WORLD_DIR/data"

# Generate docker-compose.yml
echo -e "${BLUE}🐳${NC} Generating docker-compose.yml..."

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

# Copy shared config
echo -e "${BLUE}📋${NC} Copying shared config..."
"$SCRIPTS_DIR/load-configs.sh" "$WORLD_NAME"

echo ""
echo -e "${GREEN}✅ World '$WORLD_NAME' created successfully!${NC}"
echo ""
echo "Configuration:"
echo "  Folder:      worlds/$WORLD_NAME/"
echo "  LEVEL_NAME:  $LEVEL_NAME"
echo "  SERVER_NAME: $SERVER_NAME"
echo "  Port:        $PORT"
echo ""
echo "Next steps:"
echo "  Start the world:  ./scripts/start-world.sh $WORLD_NAME"
echo ""
