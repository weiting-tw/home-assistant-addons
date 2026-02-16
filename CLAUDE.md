# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Home Assistant add-on: **Claude Terminal** — a web-based terminal with Claude Code CLI pre-installed.

Forked from [heytcass/home-assistant-addons](https://github.com/heytcass/home-assistant-addons) with security hardening.

## Security Design Principles

1. **No `/config` mount** — the add-on cannot access `secrets.yaml` or other HA config files
2. **Minimal privileges** — `hassio_role: default`, no `homeassistant_api`, no `auth_api`
3. **Minimal packages** — only essential tools installed in the container
4. **All persistent data in `/data`** — credentials, packages, state

## Architecture

### Add-on Structure (claude-terminal/)
- **config.yaml** — HA add-on configuration (multi-arch, ingress, ports)
- **Dockerfile** — Alpine-based container with Node.js and Claude Code CLI
- **build.yaml** — Multi-architecture build configuration
- **run.sh** — Main startup script with environment init and ttyd terminal
- **scripts/** — Helper scripts (auth, session picker, health check, persist-install)

### Data Storage
All persistent data lives in `/data` (HA Supervisor guaranteed writable):
- `/data/.config/claude/` — Claude credentials
- `/data/home/` — HOME directory
- `/data/.cache/` — cache
- `/data/persistent-packages.json` — saved package list

### Key Environment Variables
- `ANTHROPIC_CONFIG_DIR=/data/.config/claude`
- `HOME=/data/home`
- `XDG_CONFIG_HOME=/data/.config`

## Development

```bash
nix develop          # Enter dev shell
build-addon          # Build with Podman
run-addon            # Run locally on :7681
lint-dockerfile      # Lint Dockerfile
```

## File Conventions
- Shell scripts: `#!/usr/bin/with-contenv bashio`
- Indentation: 2 spaces YAML, 4 spaces shell
- Credential files: 600 permissions
