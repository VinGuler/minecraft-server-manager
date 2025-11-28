FROM itzg/minecraft-bedrock-server:latest

# Set environment variables for the server
ENV SERVER_NAME="My Minecraft Server"
ENV SERVER_PORT="19132"
ENV MAX_PLAYERS="10"

# Expose the server port
EXPOSE 19132/udp

# Install npm dependencies
RUN apt-get update && apt-get install -y npm && npm install

# Copy server configuration files
COPY ../src/config/server-config.json /data/server-config.json
COPY ../src/permissions/permissions.json /data/permissions.json

# Start the Minecraft Bedrock server
CMD ["start"]