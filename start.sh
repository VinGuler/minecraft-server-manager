#!/bin/bash

# Navigate to the server directory used by itzg image
cd /data

# Start Bedrock server but filter noisy behavior messages
# Only removes AI spam, keeps everything else
start 2>&1 \
  | grep -v 'attack_interval' \
  | grep -v 'nearest_attackable_target' \
  | grep -v 'behavior.nearest_attackable_target'
