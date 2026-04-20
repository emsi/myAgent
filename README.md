# myAgent

A Docker-based environment for running AI agent CLIs (Codex, Claude Code, Gemini CLI, OpenCode) against a local workspace, with persistent agent state via a named volume.

## Overview

The container launches a chosen agent CLI (`AGENT_ENGINE`) inside a fully-featured development environment (Ubuntu 24.04 + build tools + Byobu/tmux). The workspace directory is bind-mounted at `/workspace`, and the agent's home directory is stored in a Docker named volume so state (config, credentials, history) survives container restarts.

## Quick Start

```bash
# Start the agent container in the background
docker compose up -d

# Attach to the running agent session
# (uses the bin/ helper scripts)
```

See the `bin/` directory for attach/start helper scripts.

## Configuration

### Build Arguments (Dockerfile)

| Argument | Default | Description |
|---|---|---|
| `INSTALL_CODEX_CLI` | `1` | Install `@openai/codex` globally |
| `INSTALL_CLAUDE_CODE` | `0` | Install `@anthropic-ai/claude-code` globally |
| `INSTALL_GEMINI_CLI` | `0` | Install `@google/gemini-cli` globally |
| `INSTALL_OPENCODE` | `0` | Install `opencode-ai` globally |

### Runtime Environment Variables

| Variable | Default | Description |
|---|---|---|
| `AGENT_CONTAINER_NAME` | `agent-dev` | Name of the running container |
| `WORKSPACE_DIR` | `./` | Host path mounted at `/workspace` inside the container |

### Agent Engine

The `AGENT_ENGINE` environment variable (default: `codex`) controls which CLI is launched as the container entrypoint. Override it to switch agents:

```bash
AGENT_ENGINE=claude docker compose up
```

## Volumes & Mounts

| Host path | Container path | Purpose |
|---|---|---|
| `$WORKSPACE_DIR` | `/workspace` | Code the agent works on |
| `agent_home` (named volume) | `/agent` | Agent home: config, credentials, history |
| `./auth.json` | `/agent/.codex/auth.json` | Codex authentication credentials |

## Entrypoint Behaviour

`entrypoint.sh` runs at container start:

1. Configures Byobu to use screen-style key bindings (Ctrl-A prefix).
2. Creates a default Codex config at `/agent/.codex/config.toml` if none exists:
   - Approval policy: `never` (fully autonomous)
   - Sandbox mode: `danger-full-access`
   - Workspace `/workspace` is marked as `trusted`
   - Default model: `gpt-5.4-mini` with `medium` reasoning effort
   - Codex apps are disabled (`[features] apps = false`)
3. Creates a default Claude Code config at `/agent/.claude/settings.json` if none exists:
   - Permission mode: `bypassPermissions` (YOLO mode)
   - Skip dangerous-mode confirmation prompt: `true`
   - Plugins are not enabled by default (`"enabledPlugins": {}`)
4. Execs the agent CLI specified by `AGENT_ENGINE`, forwarding all arguments.

## Installed Tools

The image includes a broad set of developer tools:

- **Shell / terminal**: Byobu, tmux, bash-completion
- **VCS**: git, git-lfs
- **Search**: ripgrep, fd-find, fzf
- **Editors**: vim
- **Languages & runtimes**: Node.js/npm, Python 3, Rust/Cargo
- **Build tools**: gcc/g++, clang, cmake, ninja, meson, autoconf
- **Utilities**: jq, yq, curl, wget, bat, tree, htop, zip/unzip, rsync, socat
- **Debug / trace**: lsof, strace, gdb
- **Network**: iproute2, ping, dig, net-tools
- **Lint**: shellcheck

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Container image definition |
| `entrypoint.sh` | Container startup script |
| `docker-compose.yaml` | Service definition and volume wiring |
| `auth.json` | Codex auth credentials (bind-mounted into container; not committed) |
