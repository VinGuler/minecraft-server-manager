# Deployment Guide for Minecraft Bedrock Edition Server

This guide provides step-by-step instructions to deploy the Minecraft Bedrock Edition server on a Linux machine using Docker.

## Prerequisites
- A Linux machine with Docker installed.
- Basic knowledge of terminal commands.
- An existing Minecraft world (optional).

## Steps

### 1. Clone the Repository
```bash
git clone https://github.com/VinGuler/minecraft-server-manager.git
cd minecraft-server-manager
```

### 2. Install Dependencies
Ensure `npm` is installed on your system. Run:
```bash
npm install
```

### 3. Build the Docker Image
Navigate to the `docker` directory and build the Docker image:
```bash
docker build -t minecraft-server-manager ./docker
```

### 4. Run the Docker Container
Run the server container:
```bash
docker run -d -p 19132:19132/udp minecraft-server-manager
```

### 5. Add an Existing World (Optional)
If you have an existing Minecraft world, follow these steps:

1. **Export the World**
   - From your Minecraft client, export the world as a `.mcworld` file.

2. **Upload the World**
   - Transfer the `.mcworld` file to the Linux machine using `scp` or any file transfer method.
   ```bash
   scp my_world.mcworld user@your-server:/path/to/upload/
   ```

3. **Extract the World**
   - Use the provided script to extract and place the world in the correct directory:
   ```bash
   ./scripts/import-world.sh /path/to/upload/my_world.mcworld
   ```

### 6. Verify the Server
Check the server logs to ensure it is running correctly:
```bash
docker logs <container_id>
```

Your Minecraft Bedrock Edition server is now deployed and ready to use!