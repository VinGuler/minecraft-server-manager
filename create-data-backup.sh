#!/usr/bin/env bash
set -e

# Base directory = where the script is located
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

DATA_DIR="${BASE_DIR}/data"
BACKUP_DIR="$HOME/backups"

# Date + unique 4-char code
DATE_STR=$(date +"%Y-%m-%d")
UNIQUE_CODE=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)

# Backup file
BACKUP_NAME="${DATE_STR}__backup__${UNIQUE_CODE}.zip"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Ensure no more than 3 backups exist
BACKUP_COUNT=$(ls -1t "$BACKUP_DIR" | wc -l)
if [ "$BACKUP_COUNT" -gt 3 ]; then
  OLDEST_BACKUP=$(ls -1t "$BACKUP_DIR" | tail -1)
  rm -f "$BACKUP_DIR/$OLDEST_BACKUP"
  echo "🗑️ Deleted oldest backup: $OLDEST_BACKUP"
fi

# Create backup (zip only the data folder)
cd "$BASE_DIR"
zip -r "$BACKUP_PATH" "data"

echo "✅ Backup created:"
echo "$BACKUP_PATH"
