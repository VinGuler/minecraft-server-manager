# Minecraft Server Manager

Manage multiple Minecraft Bedrock Edition servers on a VPS using Docker, with Windows scripts for uploading worlds and downloading backups.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Windows PC (Local)                                         │
│  ├── uploads/          .mcworld files to upload             │
│  ├── backups/          Downloaded backups                   │
│  └── scripts/*.ps1     PowerShell scripts (upload/download) │
└─────────────────────────────────────────────────────────────┘
                              │ SSH/SCP
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  VPS (Remote)                                               │
│  ├── worlds/           Per-world Docker configs + data      │
│  │   ├── home/                                              │
│  │   │   ├── docker-compose.yml                             │
│  │   │   └── data/     Server data (worlds, configs)        │
│  │   └── creative/                                          │
│  ├── uploads/          Uploaded .mcworld files              │
│  ├── config/           Shared config (permissions, etc.)    │
│  └── scripts/*.sh      Bash scripts (server management)     │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
minecraft-server-manager/
├── config/                  # Shared config files copied to all worlds
│   ├── permissions.json     # Player permissions (operator, member, visitor)
│   └── server.properties    # Default server properties
├── scripts/
│   ├── create-world.sh      # Create a new world config (VPS)
│   ├── extract-world.sh     # Extract uploaded .mcworld file (VPS)
│   ├── start-world.sh       # Start a world's Docker container (VPS)
│   ├── stop-world.sh        # Stop a world (with optional backup) (VPS)
│   ├── list-worlds.sh       # List all worlds and their status (VPS)
│   ├── backup-world.sh      # Backup a single world (VPS)
│   ├── backup-worlds.sh     # Backup all worlds (VPS)
│   ├── restore-world.sh     # Restore a world from backup (VPS)
│   ├── load-configs.sh      # Copy shared config to world(s) (VPS)
│   ├── upload-world.ps1     # Upload .mcworld from Windows to VPS
│   └── download-backups.ps1 # Download backups from VPS to Windows
├── worlds/                  # Each world has its own folder
│   └── <world-name>/
│       ├── docker-compose.yml
│       └── data/            # Minecraft server data
├── uploads/                 # Staging area for .mcworld files
├── backups/                 # Local backup storage (Windows)
├── Dockerfile               # Base image (itzg/minecraft-bedrock-server)
└── docker-compose.yml       # Root compose (not typically used)
```

## Prerequisites

**On VPS:**
- Docker and Docker Compose
- This repo cloned to `~/minecraft-server-manager`

**On Windows (for upload/download scripts):**
- SSH access to VPS configured (key-based auth recommended)
- PowerShell

## Quick Start

### Creating a New World (on VPS)

```bash
cd ~/minecraft-server-manager
./scripts/create-world.sh
```

This prompts for:
- World name (folder name, e.g., `home`)
- LEVEL_NAME (in-game world name)
- SERVER_NAME (shows in server list)
- Port (default: 19132)

### Uploading an Existing World (from Windows)

1. Export your world from Minecraft as a `.mcworld` file
2. Place it in `uploads/` folder (named `<world-name>.mcworld`)
3. Run the upload script:

```powershell
.\scripts\upload-world.ps1 -WorldName home -FilePath ".\uploads\home.mcworld"
```

4. On the VPS, extract and set up:

```bash
./scripts/extract-world.sh home
```

### Starting/Stopping Worlds (on VPS)

```bash
# List all worlds and their status
./scripts/list-worlds.sh

# Start a world
./scripts/start-world.sh home

# Stop a world (prompts for backup)
./scripts/stop-world.sh home

# Stop with automatic backup
./scripts/stop-world.sh home --backup
```

### Backups

**On VPS:**
```bash
# Backup a single world (stop server first for consistent backup)
./scripts/stop-world.sh home
./scripts/backup-world.sh home

# Backup all worlds
./scripts/backup-worlds.sh
```

Backups are stored in `~/backups/<world-name>/` with max 3 backups per world.

Backups include the **full data directory**: world chunks, player data (inventory, position, achievements), permissions, allowlist, and server properties.

**Restore from backup (on VPS):**
```bash
# Interactive restore (lists available backups)
./scripts/restore-world.sh home

# Or specify backup file directly
./scripts/restore-world.sh home 2026-01-30__backup__Ab12.zip
```

**Download backups to Windows:**
```powershell
# Download all world backups
.\scripts\download-backups.ps1 -All

# Download specific world
.\scripts\download-backups.ps1 -WorldName home
```

## Scripts Reference

### VPS Scripts (Bash)

| Script | Description |
|--------|-------------|
| `create-world.sh` | Interactive wizard to create a new world config |
| `extract-world.sh` | Extract `.mcworld` file and set up Docker config |
| `start-world.sh` | Start a world's Docker container |
| `stop-world.sh` | Stop a world (with optional backup) |
| `list-worlds.sh` | Show all worlds with status, port, and server name |
| `backup-world.sh` | Create a full backup of a single world |
| `backup-worlds.sh` | Backup all configured worlds |
| `restore-world.sh` | Restore a world from a backup file |
| `load-configs.sh` | Copy shared config to one or all worlds |

### Windows Scripts (PowerShell)

| Script | Description |
|--------|-------------|
| `upload-world.ps1` | Upload a `.mcworld` file to VPS |
| `download-backups.ps1` | Download backups from VPS |

## Connecting to Your Server

After starting a world, connect from Minecraft Bedrock Edition:

- **Address:** Your VPS IP
- **Port:** The port configured for that world (default: 19132)

## Docker Commands

```bash
# View logs
docker logs -f mc-<world-name>

# Attach to console (send commands)
docker attach mc-<world-name>
# Detach with Ctrl+P, Ctrl+Q

# Check running containers
docker ps
```

## Configuration

### Shared Config (`config/`)

Files in `config/` are copied to each world's `data/` folder when starting:

- `permissions.json` - Player permissions
- `server.properties` - Server settings

Edit these files and run `./scripts/load-configs.sh` to apply to all worlds.

### Per-World Config

Each world's `docker-compose.yml` contains:
- Port mapping
- LEVEL_NAME and SERVER_NAME
- MAX_PLAYERS
- Volume mount for persistent data
