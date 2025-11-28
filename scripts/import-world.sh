#!/bin/bash

# Script to import a Minecraft world into the server

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path_to_mcworld_file>"
  exit 1
fi

MCWORLD_FILE=$1
WORLD_NAME=$(basename "$MCWORLD_FILE" .mcworld)

# Ensure the file exists
if [ ! -f "$MCWORLD_FILE" ]; then
  echo "File not found: $MCWORLD_FILE"
  exit 1
fi

# Create the worlds directory if it doesn't exist
mkdir -p /data/worlds

# Extract the .mcworld file
unzip "$MCWORLD_FILE" -d "/data/worlds/$WORLD_NAME"

if [ $? -eq 0 ]; then
  echo "World imported successfully: $WORLD_NAME"
else
  echo "Failed to import world."
  exit 1
fi