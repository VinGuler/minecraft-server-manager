#!/usr/bin/env bash

# list-worlds.sh - List all worlds and their status

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORLDS_DIR="$BASE_DIR/worlds"

echo ""
echo "🌍 Minecraft Worlds"
echo "==================="
echo ""

if [ ! -d "$WORLDS_DIR" ]; then
    echo "No worlds directory found."
    exit 0
fi

# Check if any worlds exist
world_count=$(find "$WORLDS_DIR" -maxdepth 1 -type d ! -path "$WORLDS_DIR" 2>/dev/null | wc -l)
if [ "$world_count" -eq 0 ]; then
    echo "No worlds configured yet."
    echo ""
    echo "Create one with: ./scripts/create-world.sh"
    exit 0
fi

# Print header
printf "%-15s %-12s %-8s %-20s\n" "WORLD" "STATUS" "PORT" "SERVER NAME"
printf "%-15s %-12s %-8s %-20s\n" "-----" "------" "----" "-----------"

for world_dir in "$WORLDS_DIR"/*/; do
    if [ -d "$world_dir" ]; then
        world=$(basename "$world_dir")
        compose_file="$world_dir/docker-compose.yml"

        # Default values
        status="NOT CONFIGURED"
        port="-"
        server_name="-"

        if [ -f "$compose_file" ]; then
            # Extract port from docker-compose.yml
            port=$(grep -oP "^\s*-\s*['\"]?\K\d+" "$compose_file" 2>/dev/null | head -1)
            [ -z "$port" ] && port="19132"

            # Extract server name
            server_name=$(grep -oP 'SERVER_NAME:\s*["\x27]?\K[^"\x27]+' "$compose_file" 2>/dev/null | head -1)
            [ -z "$server_name" ] && server_name="-"

            # Check container status
            container_name="mc-$world"
            container_status=$(docker ps --filter "name=^${container_name}$" --format "{{.Status}}" 2>/dev/null)

            if [ -n "$container_status" ]; then
                status="🟢 RUNNING"
            else
                # Check if container exists but stopped
                exists=$(docker ps -a --filter "name=^${container_name}$" --format "{{.Status}}" 2>/dev/null)
                if [ -n "$exists" ]; then
                    status="🔴 STOPPED"
                else
                    status="⚪ READY"
                fi
            fi
        fi

        printf "%-15s %-12s %-8s %-20s\n" "$world" "$status" "$port" "$server_name"
    fi
done

echo ""
