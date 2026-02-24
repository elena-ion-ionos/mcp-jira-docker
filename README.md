# Claude Code Dev Workspace

A dev container workspace for working with Claude Code, including MCP (Model Context Protocol) integration for Jira and Confluence, and multi-agent orchestration scripts.

---

## Repository Structure

```
.
├── .devcontainer/
│   ├── devcontainer.json       # Dev container configuration
│   ├── Dockerfile              # Container image definition
│   ├── post-create.sh          # Runs after container creation (MCP setup)
│   └── init-firewall.sh        # Firewall rules (runs on container start)
├── .mcp.json                   # Points Claude Code to the MCP server (SSE)
├── orchestrator.sh             # Multi-agent tmux orchestrator (3 fixed agents)
└── swarm.sh                    # Multi-agent tmux swarm (configurable agents)
```

---

## How It Works

The dev container connects to an MCP Atlassian server running **on the host machine** via SSE at `http://172.17.0.1:9000/sse` (Docker bridge IP). This gives Claude Code inside the container access to Jira and Confluence without exposing credentials inside the container image.

```
┌─────────────────────────────┐          ┌──────────────────────────────┐
│   Dev Container             │          │   Host Machine               │
│                             │          │                              │
│   Claude Code               │  SSE     │   mcp-atlassian              │
│   (.mcp.json → 172.17.0.1) ├─────────►│   (pip install, :9000)      │
│                             │          │                              │
└─────────────────────────────┘          └──────────────────────────────┘
```

---

## New Laptop Setup

> Jump to the section for your OS:
> - [Linux (Ubuntu/Debian)](#linux-ubuntudebian)
> - [macOS](#macos)

---

## Linux (Ubuntu/Debian)

### 1. Install Prerequisites

**Docker:**

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

Enable Docker to start on boot and add your user to the `docker` group (no `sudo` needed):

```bash
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
```

**VS Code** with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), and **Git**.

---

### 2. Clone the Repository

```bash
git clone <repo-url>
cd <repo-name>
```

---

### 3. Create the Workspace Directory

The bind mount will fail if the source path does not exist:

```bash
mkdir -p ~/Workspace/<YOUR_FOLDER>
```

---

### 4. Configure `.env` and Start the Stack

Edit the `.env` file in the repository root:

```bash
# .env

# Workspace folder to mount into the dev container
WORKSPACE_PATH=/home/<YOUR_USERNAME>/Workspace/<YOUR_FOLDER>

# Atlassian URLs
JIRA_URL=https://hosting-jira.1and1.org
CONFLUENCE_URL=https://confluence.united-internet.org

# Personal access tokens
# Jira: Profile → Security → Create API token at https://hosting-jira.1and1.org
# Confluence: Profile → Security → Create API token at https://confluence.united-internet.org
JIRA_PERSONAL_TOKEN=<your-jira-personal-token>
CONFLUENCE_PERSONAL_TOKEN=<your-confluence-personal-token>
```

> **Security:** Never commit `.env` with real tokens. Add `.env` to `.gitignore`.

Then start the full stack (MCP server + dev container):

```bash
docker-compose up -d
```

Verify the MCP server is up:

```bash
curl http://localhost:9000/sse
# An SSE stream should open
```

---

### 5. Open the Dev Container

In VS Code: `Ctrl+Shift+P` → **Dev Containers: Reopen in Container**

`post-create.sh` will pre-cache `mcp-atlassian` and write the MCP config.
`init-firewall.sh` will lock down outbound traffic and allow the host network (`172.17.0.0/24`).

---

### 7. Authenticate Claude Code (first time only)

```bash
claude
```

Follow the browser login flow. Credentials are stored in the `/home/node/.claude` Docker volume.

---

### 8. Verify

```bash
claude mcp list          # should show: mcp-atlassian
curl http://172.17.0.1:9000/sse   # should open an SSE stream
```

---

## macOS

Docker Desktop on macOS runs containers inside a Linux VM. This changes networking, path conventions, and removes the need for several Linux-only steps.

### 1. Install Prerequisites

**Homebrew** (if not already installed):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Docker Desktop:**

```bash
brew install --cask docker
```

Open Docker Desktop from Applications and let it finish starting. It auto-starts on login — no `systemctl`, no `usermod`, no `iptables-persistent` needed.

**VS Code** and **Git:**

```bash
brew install --cask visual-studio-code
brew install git
```

Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) in VS Code.

---

### 2. Clone the Repository

```bash
git clone <repo-url>
cd <repo-name>
```

---

### 3. Create the Workspace Directory

```bash
mkdir -p ~/Workspace/<YOUR_FOLDER>
```

---

### 4. Update `.mcp.json` for macOS

On macOS, `172.17.0.1` is **not** the host IP — Docker Desktop uses a separate VM. Replace it with `host.docker.internal`, which Docker Desktop automatically resolves to the host:

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "type": "sse",
      "url": "http://host.docker.internal:9000/sse"
    }
  }
}
```

---

### 5. Configure `.env` and Start the Stack

Edit the `.env` file in the repository root. On macOS, home directories are under `/Users/`:

```bash
# .env

# Workspace folder to mount into the dev container
WORKSPACE_PATH=/Users/<YOUR_USERNAME>/Workspace/<YOUR_FOLDER>

# Atlassian URLs
JIRA_URL=https://hosting-jira.1and1.org
CONFLUENCE_URL=https://confluence.united-internet.org

# Personal access tokens
# Jira: Profile → Security → Create API token at https://hosting-jira.1and1.org
# Confluence: Profile → Security → Create API token at https://confluence.united-internet.org
JIRA_PERSONAL_TOKEN=<your-jira-personal-token>
CONFLUENCE_PERSONAL_TOKEN=<your-confluence-personal-token>
```

> **Security:** Never commit `.env` with real tokens. Add `.env` to `.gitignore`.

Then start the full stack (MCP server + dev container):

```bash
docker-compose up -d
```

Verify the MCP server is up:

```bash
curl http://localhost:9000/sse
# An SSE stream should open
```

---

### 6. Open the Dev Container

In VS Code: `Cmd+Shift+P` → **Dev Containers: Reopen in Container**

`post-create.sh` will pre-cache `mcp-atlassian` and write the MCP config.
`init-firewall.sh` runs inside the Linux container (not on macOS) — `iptables` works fine within the container regardless of the host OS. The firewall detects the Docker VM's default gateway and allows traffic to `host.docker.internal` automatically.

---

### 7. Authenticate Claude Code (first time only)

```bash
claude
```

Follow the browser login flow. Credentials are stored in the `/home/node/.claude` Docker volume.

---

### 8. Verify

```bash
claude mcp list                          # should show: mcp-atlassian
curl http://host.docker.internal:9000/sse   # should open an SSE stream
```

---

## Multi-Agent Scripts

Two scripts are provided to launch multiple Claude Code agents in a tmux session, each in a separate pane with a defined role.

### `orchestrator.sh` — 3 Fixed Agents (PM, Dev, QA)

```bash
./orchestrator.sh [session-name] [project-dir]
```

**Examples:**
```bash
./orchestrator.sh                          # session: claude-swarm, dir: current
./orchestrator.sh my-session backup-service
```

**Layout:**

```
Window 0 (Orchestrator):
┌──────────────────┬──────────────────┐
│  Orchestrator-PM │  Dev-Agent       │
│                  ├──────────────────┤
│                  │  QA-Agent        │
└──────────────────┴──────────────────┘
Window 1 (Shell): manual commands
```

---

### `swarm.sh` — Configurable Agents

```bash
./swarm.sh <project-dir> [session-name]
```

**Examples:**
```bash
./swarm.sh backup-service
./swarm.sh backup-service s3-swarm
AGENTS="PM,Dev,QA,Security" ./swarm.sh backup-service
```

Default agents: `PM`, `Dev`, `Server`. Override with the `AGENTS` environment variable (comma-separated).

**Tmux controls (both scripts):**

| Action | Keys |
|---|---|
| Attach to session | `tmux attach -t <session>` |
| Switch windows | `Ctrl-b` + `0` / `1` |
| Switch panes | `Ctrl-b` + arrow keys |
| Detach | `Ctrl-b` + `d` |
| Kill session | `tmux kill-session -t <session>` |

---

## Firewall

The container runs with a strict outbound firewall. Allowed domains include:

- GitHub (`github.com`, `ghcr.io`, GitHub IP ranges)
- Anthropic (`api.anthropic.com`, `statsig.anthropic.com`)
- NPM (`registry.npmjs.org`)
- PyPI (`pypi.org`, `files.pythonhosted.org`, Fastly CDN ranges)
- VS Code Marketplace
- Jira (`hosting-jira.1and1.org`)
- Confluence (`confluence.united-internet.org`)
- Host network (`172.17.0.0/24`) — required for MCP SSE

All other outbound traffic is rejected.
