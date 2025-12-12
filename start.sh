#!/bin/bash

LOG_FILTER_PATTERN='attack_interval|nearest_attackable_target|behavior\.nearest_attackable_target'

# --- Execution ---
exec /start "$@" 2>&1 \
  | grep --line-buffered -vE "$LOG_FILTER_PATTERN"