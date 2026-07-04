# Don't Starve Together Dedicated Server on Docker

A customizable, lightweight, and production-ready **Don't Starve Together (DST) Dedicated Server** Docker image designed for easy hosting on **Coolify**, Docker Compose, or standalone Docker.

---

## Features

- 🎮 **Dynamic Configuration**: Automatically builds your `cluster.ini`, `server.ini`, and `worldgenoverride.lua` configuration files from environment variables.
- 🔀 **Flexible Shard Modes**:
  - `Single`: Surface-only (lightweight, runs only the Master shard, caves disabled).
  - `Master` / `Caves`: Multi-container split (scale them independently using Docker Compose).
  - `Both`: Run both Master (Surface) and Caves shards inside the **same container** (extremely simple, single-container setup).
- 🔌 **Steam Workshop Mods**: Auto-downloads and enables mods via `DST_MODS` (comma-separated ID list) while preserving manual settings.
- 💾 **Graceful Shutdown**: Automatically captures termination signals (`SIGTERM`/`SIGINT`) to force-save the worlds and exit cleanly, preventing rollback/progress loss.
- 🔄 **Auto-Updates**: Option to verify and download server updates on container boot.
- 🐳 **GitHub Actions Built**: Auto-publishes to GitHub Container Registry (GHCR) and Docker Hub.

---

## 🛠️ Environment Variables

### General Cluster Settings
| Variable | Default | Description |
| :--- | :--- | :--- |
| `DST_CLUSTER_TOKEN` | *Required* | Your Klei Server Token. [Get it here](https://accounts.klei.com/account/info). |
| `DST_CLUSTER_NAME` | `DST Dedicated Server` | The public name of your server in the browser. |
| `DST_CLUSTER_DESC` | `A Don't Starve Together server running on Docker` | Server description. |
| `DST_CLUSTER_PASS` | `""` | Password required to join the server. |
| `DST_CLUSTER_INTENTION` | `cooperative` | Server style: `cooperative`, `competitive`, `social`, `madness`. |
| `DST_GAME_MODE` | `survival` | Game style: `survival`, `endless`, `wilderness`. |
| `DST_MAX_PLAYERS` | `6` | Maximum concurrent players (1 to 64). |
| `DST_PVP` | `false` | Enable/disable PvP damage. |
| `DST_PAUSE_WHEN_EMPTY` | `true` | Pause the world progression when no players are online. |
| `DST_VOTE_ENABLED` | `true` | Allow players to start votes (kick, rollback, etc.). |
| `DST_TICK_RATE` | `30` | Server update rate (ticks per second). |
| `DST_AUTO_UPDATE` | `false` | Set to `true` to check and apply game updates on container start. |

### Sharding & Network Settings
| Variable | Default | Description |
| :--- | :--- | :--- |
| `DST_SHARD_MODE` | `Single` | Execution mode: `Single` (no caves), `Master`, `Caves`, `Both` (both in one container). |
| `DST_CLUSTER_KEY` | `dst_cluster_key` | Secret key used to encrypt shard-to-shard communication. |
| `DST_MASTER_IP` | `127.0.0.1` | IP address of the Master server (used by the Caves container to connect). |
| `DST_MASTER_PORT` | `10888` | UDP port used for internal communication between Master and Caves. |
| `DST_SERVER_PORT` | `10999` | External UDP port players connect to (Master game port). |
| `DST_CAVES_PORT` | `11000` | External UDP port for Caves (used only when `DST_SHARD_MODE=Both`). |

### Mods Settings
| Variable | Default | Description |
| :--- | :--- | :--- |
| `DST_MODS` | `""` | Comma-separated list of Steam Workshop Mod IDs (e.g., `345678,987654`). |

---

## 🚀 Coolify Deployment Guide

In Coolify, you can deploy this server in two different ways depending on your resource limitations and preferences:

### Option A: Single Container Setup (Surface + Caves combined)
*Ideal for quick setups, lower memory usage, and simple port forwarding.*

1. In Coolify, create a new **Private Application**.
2. Select your repository (or point to `ghcr.io/YOUR_USERNAME/dst-dedicated-server:latest`).
3. Under the **Ports** settings, map the following UDP ports:
   - `10999:10999/udp` (Master game port)
   - `11000:11000/udp` (Caves game port)
4. Under **Environment Variables**, define at least:
   - `DST_CLUSTER_TOKEN` = `your_token_here`
   - `DST_SHARD_MODE` = `Both`
5. Under **Storage / Volumes**, configure a persistent volume mount pointing to `/data`. E.g., `dst-data:/data`.
6. Deploy! The container will automatically set up both the Master and Caves servers.

### Option B: Docker Compose Setup (Recommended for busy servers)
*Runs Master and Caves as separate containers sharing the same volume. Best for CPU core utilization.*

1. In Coolify, add a new resource and select **Docker Compose**.
2. Paste the contents of [docker-compose.yml](docker-compose.yml).
3. Set your environment variables (like `DST_CLUSTER_TOKEN` on the `master` service).
4. Configure the shared volume so that both containers can read files under `/data`.
5. Deploy the stack. Coolify will build (or pull) the image once, then launch two connected container processes.

---

## 📂 Directory Structure & Custom Configuration

All server saves, configs, and logs are persisted inside the mounted `/data` directory:

```text
/data/DoNotStarveTogether/Cluster_1/
├── cluster.ini          # Auto-generated from environment variables
├── cluster_token.txt    # Your Klei server token
├── Master/
│   ├── server.ini       # Auto-generated shard configuration
│   └── worldgenoverride.lua  # Default Forest world settings
└── Caves/
    ├── server.ini       # Auto-generated shard configuration
    └── worldgenoverride.lua  # Default Caves world settings
```

### Customize World Settings
If you want to customize your world generation (e.g., changing resource spawn rates, seasons, etc.):
1. Generate the world settings in your local DST Game Client using the in-game UI.
2. Go to your local save folder (usually `Documents/Klei/DoNotStarveTogether/Cluster_X/`).
3. Copy the generated `leveldataoverride.lua` (or `worldgenoverride.lua`) into the server's `/data/DoNotStarveTogether/Cluster_1/Master/` (for Surface) or `/Caves/` (for Caves) folder.
4. Restart the server container.

### Customize Mod Settings
If you want to configure mod settings (like changing default options for an active mod):
1. The server will auto-create a `modoverrides.lua` inside your shard folders (`Master/` and `Caves/`) when you specify `DST_MODS`.
2. Edit those files manually inside the mounted `/data` volume to customize the mods.
3. The entrypoint script will detect that the files already exist and will **not** overwrite your customizations on subsequent starts.

---

## 🔒 Graceful Shutdowns

Don't Starve Together dedicated servers save the world dynamically, but can lose progress if killed suddenly. This container has active signal interception:
- When a `docker stop` or Coolify stop command is received, the container traps the `SIGTERM` signal.
- The script immediately forwards this signal to both the Master and Caves server processes.
- The game will write out the current state to the save files (seen in logs as `Saving...`).
- The container waits for the server processes to close cleanly before exiting.
