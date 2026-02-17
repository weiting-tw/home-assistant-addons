# Changelog

All notable changes to this project will be documented in this file.

## [1.9.0] - 2026-02-17

### Added
- Fixed toolbar with action buttons (Resume/New/List/Shell/Stop) for mobile use
- tmux-based session persistence — reconnecting resumes previous Claude session
- Custom Node.js web UI wrapping ttyd with button API

## [1.8.0] - 2026-02-16

### ⚠️ Breaking Changes
- **Removed `/config` mount** — `secrets.yaml` and other Home Assistant config files are no longer accessible from within the add-on container
- **WORKDIR changed** from `/config` to `/data` — any scripts referencing `/config` need to be updated
- **Reduced `hassio_role`** from `manager` to `default`
- **Disabled `homeassistant_api`** and `auth_api` — direct HA API calls from within the container are no longer available

### 🔒 Security
- Removed config directory mount (`map: config:rw`) to prevent exposure of `secrets.yaml`
- Reduced container privileges (`hassio_role: default`)
- Removed unnecessary system packages (vim, wget, tree, yq, py3-requests, py3-aiohttp, py3-yaml, py3-beautifulsoup4) to minimize attack surface
- Added `.gitignore` rules for sensitive files (secrets.yaml, *.key, *.pem, .env)
- Deleted committed `.claude.json` containing user data
- Added `.gitleaks.toml` for secret scanning configuration

### 🧪 CI/CD
- Added comprehensive test workflow with 4 jobs:
  - **lint** — Hadolint (Dockerfile), ShellCheck (shell scripts), yamllint (YAML files)
  - **security-scan** — Gitleaks secret scanning, `.gitignore` pattern validation, config.yaml security settings enforcement
  - **build-test** — Docker build, container smoke test, security verification (`/config` not accessible, WORKDIR is `/data`)
  - **config-validation** — Schema validation, semver version check, architecture completeness, build.yaml and repository.yaml validation
- Updated `builder.yml` with path filters (only triggers on `claude-terminal/` changes)
- Removed `claude-code-review.yml` (requires API key not configured)

### 📝 Documentation
- Updated all references from original fork author to current maintainer
- Updated repository URLs throughout
- Rewrote `CLAUDE.md` with security-first development guidelines
- Updated `README.md` with security improvements section and fork attribution

### 🏗️ Infrastructure
- Updated `repository.yaml` maintainer info
- Updated `build.yaml` source URL
- Updated `LICENSE` copyright

## [1.7.2] - Previous Release

Stable multi-arch support with verified paths (inherited from fork).
