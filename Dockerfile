FROM itzg/minecraft-bedrock-server:latest

# Set environment variables for the server
ENV SERVER_NAME="Home MC Server"
ENV SERVER_PORT="19132"
ENV MAX_PLAYERS="10"

# Expose the server port
EXPOSE 19132/udp

# Start the Minecraft Bedrock server
CMD ["start"]