# Minecraft Server Manager - Implementation Plan

## Current State

### VPS Structure (working)
```
~/minecraft-server-manager/           # Repo (cloned here)
├── Dockerfile
├── docker-compose.yml                # Single server setup
├── config/
│   ├── permissions.json
│   └── server.properties
├── data/                             # Docker volume (gitignored)
│   └── worlds/
│       ├── Home/
│       └── MyWorld/
├── create-data-backup.sh
├── load-configs.sh
└── uploads/                          # Existing folder

~/backups/                            # Backups (outside repo)
```

### Current Docker Setup
- Uses `itzg/minecraft-bedrock-server:latest`
- Single container named "bedrock"
- Data volume: `./data:/data`
- Server data lives in `data/worlds/{LEVEL_NAME}/`

---

## Target State

### New VPS Structure
```
~/minecraft-server-manager/
├── ai/
│   └── PLAN.md
├── config/                           # SHARED config for all worlds
│   ├── permissions.json
│   └── server.properties
├── worlds/                           # Git-tracked (except data/)
│   ├── home/
│   │   ├── docker-compose.yml
│   │   └── data/                     # (gitignored) Docker volume
│   │       └── worlds/
│   │           └── Home/             # Actual world files
│   └── creative/
│       ├── docker-compose.yml
│       └── data/
│           └── worlds/
│               └── Creative/
├── uploads/                          # (gitignored) .mcworld files land here
├── backups/                          # (gitignored) Local backup copies
├── Dockerfile                        # Shared across all worlds
├── scripts/
│   ├── upload-world.ps1              # Windows: upload .mcworld to VPS
│   ├── download-backups.ps1          # Windows: download backups from VPS
│   ├── extract-world.sh              # Linux: extract .mcworld
│   ├── backup-worlds.sh              # Linux: backup all worlds
│   ├── backup-world.sh               # Linux: backup single world
│   ├── start-world.sh                # Linux: start a world
│   ├── stop-world.sh                 # Linux: stop a world
│   ├── create-world.sh               # Linux: create new world config
│   ├── load-configs.sh               # Linux: copy shared config to world(s)
│   └── list-worlds.sh                # Linux: list all worlds + status
└── .gitignore
```

### Backup Location (on VPS)
```
~/backups/
├── home/
│   ├── 2026-01-30__backup__AB12.zip
│   └── ...
└── creative/
    └── ...
```

---

## .gitignore Updates

```gitignore
# Data folders (big files, transferred via scripts)
data
worlds/*/data

# Uploads and backups
uploads
backups
```

---

## Scripts Specification

### Windows Scripts (Local Machine)

#### 1. upload-world.ps1
**Purpose:** Upload a .mcworld file to VPS

**Flow:**
1. Ask: "Enter world name (e.g., home, creative):"
2. Look for `uploads/{world_name}.mcworld` locally
3. If not found, ask for file path
4. SCP file to `~/minecraft-server-manager/uploads/` on VPS
5. Print next steps

**Usage:**
```powershell
.\scripts\upload-world.ps1
# or
.\scripts\upload-world.ps1 -WorldName home -FilePath "C:\path\to\world.mcworld"
```

#### 2. download-backups.ps1
**Purpose:** Download backups from VPS to local machine

**Flow:**
1. Ask: "Download all worlds or specific? [all/world_name]:"
2. SCP from `~/backups/{world}/` to local `backups/{world}/`
3. Show download summary

**Usage:**
```powershell
.\scripts\download-backups.ps1
# or
.\scripts\download-backups.ps1 -WorldName home
.\scripts\download-backups.ps1 -All
```

---

### Linux Scripts (VPS)

#### 1. extract-world.sh
**Purpose:** Extract uploaded .mcworld into world's data folder

**Flow:**
1. If no arg, ask: "Enter world name:"
2. If no arg, ask: "Enter LEVEL_NAME (display name in-game):"
3. Check if `uploads/{world_name}.mcworld` exists
4. Create `worlds/{world_name}/` structure if needed
5. Generate `docker-compose.yml` if not exists (ask for SERVER_NAME, port)
6. Extract .mcworld to `worlds/{world_name}/data/worlds/{LEVEL_NAME}/`
7. Copy shared config files
8. Clean up .mcworld file
9. Print success + next steps

**Usage:**
```bash
./scripts/extract-world.sh
# or
./scripts/extract-world.sh home "Home World"
```

#### 2. create-world.sh
**Purpose:** Create a new world configuration (without importing)

**Flow:**
1. Ask: "Enter world name (folder name, lowercase):"
2. Ask: "Enter LEVEL_NAME (display name):"
3. Ask: "Enter SERVER_NAME (shows in server list):"
4. Ask: "Enter port (default 19132):"
5. Create `worlds/{world_name}/` folder
6. Generate `docker-compose.yml`
7. Create empty data structure
8. Copy shared config

**Usage:**
```bash
./scripts/create-world.sh
```

#### 3. backup-world.sh
**Purpose:** Backup a single world

**Flow:**
1. If no arg, ask: "Enter world name:"
2. Check world exists
3. Create backup at `~/backups/{world_name}/{date}__backup__{code}.zip`
4. Maintain max 3 backups (delete oldest)
5. Print backup path

**Usage:**
```bash
./scripts/backup-world.sh home
```

#### 4. backup-worlds.sh
**Purpose:** Backup ALL worlds

**Flow:**
1. Loop through all folders in `worlds/`
2. Call `backup-world.sh` for each
3. Print summary

**Usage:**
```bash
./scripts/backup-worlds.sh
```

#### 5. start-world.sh
**Purpose:** Start a world's Docker container

**Flow:**
1. If no arg, list worlds and ask: "Enter world name:"
2. Copy shared config to world's data folder
3. `cd worlds/{world_name} && docker compose up -d`
4. Print status + connection info

**Usage:**
```bash
./scripts/start-world.sh home
```

#### 6. stop-world.sh
**Purpose:** Stop a world's Docker container

**Flow:**
1. If no arg, list running worlds and ask: "Enter world name:"
2. Ask: "Create backup before stopping? [y/N]:"
3. If yes, run backup
4. `cd worlds/{world_name} && docker compose down`

**Usage:**
```bash
./scripts/stop-world.sh home
```

#### 7. list-worlds.sh
**Purpose:** List all worlds and their status

**Flow:**
1. Loop through `worlds/*/`
2. Check Docker container status for each
3. Print table: World | Status | Port | LEVEL_NAME

**Usage:**
```bash
./scripts/list-worlds.sh
```

#### 8. load-configs.sh
**Purpose:** Copy shared config to world(s)

**Flow:**
1. If arg provided, copy to that world
2. If no arg, copy to ALL worlds

**Usage:**
```bash
./scripts/load-configs.sh home
./scripts/load-configs.sh        # all worlds
```

---

## Docker Compose Template

Generated for each world at `worlds/{world_name}/docker-compose.yml`:

```yaml
services:
  minecraft:
    build: ../..
    container_name: mc-{world_name}
    ports:
      - "{port}:19132/udp"
    environment:
      EULA: "TRUE"
      LEVEL_NAME: "{LEVEL_NAME}"
      SERVER_NAME: "{SERVER_NAME}"
      MAX_PLAYERS: "10"
    volumes:
      - ./data:/data
    restart: unless-stopped
    stdin_open: true
    tty: true
```

---

## Migration Plan

### Phase 1: Setup New Structure
1. Create `worlds/` folder
2. Create `scripts/` folder
3. Update `.gitignore`
4. Move existing scripts to `scripts/`

### Phase 2: Migrate Current World
1. Create `worlds/home/` folder
2. Generate `docker-compose.yml` for home
3. Move `data/` to `worlds/home/data/`
4. Test start/stop

### Phase 3: Implement Scripts
Order of implementation:
1. `list-worlds.sh` (simple, good for testing)
2. `load-configs.sh` (needed by others)
3. `start-world.sh` / `stop-world.sh`
4. `backup-world.sh` / `backup-worlds.sh`
5. `create-world.sh`
6. `extract-world.sh`
7. `upload-world.ps1`
8. `download-backups.ps1`

### Phase 4: Test Full Flows
1. Create new world via `create-world.sh`
2. Start/stop worlds
3. Backup and restore
4. Upload and extract .mcworld
5. Download backups

---

## User Experience Details

### Interactive Prompts (Example)
```
$ ./scripts/extract-world.sh

🌍 Minecraft World Extractor
============================

Enter world name (folder name, lowercase): creative
Enter LEVEL_NAME (in-game display name): Creative World
Enter SERVER_NAME (server list name): My Creative Server
Enter port [19132]: 19133

📦 Extracting world...
✅ World extracted to: worlds/creative/data/worlds/Creative World/
✅ Docker config created: worlds/creative/docker-compose.yml
✅ Shared config copied

Next steps:
  ./scripts/start-world.sh creative
```

### Color Coding
- ✅ Green: Success
- ⚠️ Yellow: Warning
- ❌ Red: Error
- 📦 Blue: Processing

---

## Future: Web UI

Later phase - a simple web interface to:
- List all worlds with status
- Start/Stop buttons
- Trigger backup
- Upload .mcworld via drag-drop
- View backup history
- Download backups
- View container logs

Tech stack TBD (could be simple Node.js + Express, or even a static page with SSH commands via websocket).

---

## Port Management

Since only one world runs at a time (for now), all can use port 19132.

If running multiple simultaneously:
- home: 19132
- creative: 19133
- survival: 19134
- etc.

The `create-world.sh` script will ask for port and check for conflicts.

---

## Summary

| Flow | Platform | Script |
|------|----------|--------|
| Upload .mcworld | Windows | `upload-world.ps1` |
| Extract world | Linux | `extract-world.sh` |
| Create new world | Linux | `create-world.sh` |
| Start world | Linux | `start-world.sh` |
| Stop world | Linux | `stop-world.sh` |
| List worlds | Linux | `list-worlds.sh` |
| Backup one world | Linux | `backup-world.sh` |
| Backup all worlds | Linux | `backup-worlds.sh` |
| Download backups | Windows | `download-backups.ps1` |
| Load shared config | Linux | `load-configs.sh` |
