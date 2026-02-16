# Claude Terminal for Home Assistant

A secure, web-based terminal with Claude Code CLI pre-installed for Home Assistant.

> Forked from [heytcass/home-assistant-addons](https://github.com/heytcass/home-assistant-addons) with security improvements.

![Claude Terminal Screenshot](https://github.com/weiting-tw/home-assistant-addons/raw/main/claude-terminal/screenshot.png)

*Claude Terminal running in Home Assistant*

## What is Claude Terminal?

This add-on provides a web-based terminal interface with Claude Code CLI pre-installed, allowing you to use Claude's powerful AI capabilities directly from your Home Assistant dashboard.

## Features

- **Web Terminal Interface**: Access Claude through a browser-based terminal using ttyd
- **Auto-Launch**: Claude starts automatically when you open the terminal
- **Native Claude Code CLI**: Pre-installed via NPM
- **No Configuration Needed**: Uses OAuth authentication for easy setup
- **Home Assistant Integration**: Access directly from your dashboard
- **Panel Icon**: Quick access from the sidebar with the code-braces icon
- **Multi-Architecture Support**: Works on amd64, aarch64, and armv7 platforms
- **Secure Credential Management**: Persistent authentication stored in `/data/.config/claude/`
- **Persistent Package Management**: Install APK and pip packages that survive container restarts

## Security Improvements (vs upstream)

- ❌ **No `/config` mount** — `secrets.yaml` and other sensitive files are not accessible
- ⬇️ **Reduced `hassio_role`** — downgraded from `manager` to `default`
- ❌ **No HA API access** — `homeassistant_api` and `auth_api` disabled
- 🧹 **Minimal packages** — removed unnecessary Python libraries and tools to reduce attack surface

## Quick Start

```bash
# Ask Claude a question directly
claude "How can I write a Python script to control my lights?"

# Start an interactive session
claude -i

# Install packages that persist across restarts
persist-install apk vim htop
persist-install pip requests pandas
```

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the Claude Terminal add-on
3. Start the add-on
4. Click "OPEN WEB UI" or the sidebar icon to access
5. On first use, follow the OAuth prompts to log in to your Anthropic account

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `auto_launch_claude` | `true` | Auto-start Claude on terminal open |
| `persistent_apk_packages` | `[]` | APK packages to install on startup |
| `persistent_pip_packages` | `[]` | pip packages to install on startup |

## Troubleshooting

### Authentication Issues
```bash
claude-auth debug    # Show credential status
claude-logout        # Clear credentials and re-authenticate
```

### Container Issues
- Credentials are stored in `/data/.config/claude/` and persist across restarts
- Check add-on logs if the terminal doesn't load

## Documentation

For detailed usage instructions, see the [documentation](DOCS.md).

## Credits

Originally created by [heytcass](https://github.com/heytcass). This fork focuses on security hardening.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
