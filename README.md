# Claude Terminal for Home Assistant

This repository contains a custom add-on that integrates Anthropic's Claude Code CLI with Home Assistant.

> Forked from [heytcass/home-assistant-addons](https://github.com/heytcass/home-assistant-addons) with security improvements.

## Installation

To add this repository to your Home Assistant instance:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots menu in the top right corner
3. Select **Repositories**
4. Add the URL: `https://github.com/weiting-tw/home-assistant-addons`
5. Click **Add**

## Add-ons

### Claude Terminal

A web-based terminal interface with Claude Code CLI pre-installed. This add-on provides a terminal environment directly in your Home Assistant dashboard, allowing you to use Claude's powerful AI capabilities for coding, automation, and configuration tasks.

Features:
- Web terminal access through your Home Assistant UI
- Pre-installed Claude Code CLI that launches automatically
- No configuration needed (uses OAuth)
- Access to Claude's complete capabilities including:
  - Code generation and explanation
  - Debugging assistance
  - Home Assistant automation help
  - Learning resources

[Documentation](claude-terminal/DOCS.md)

## Security Improvements

Compared to the upstream fork, this version:
- **Removed `/config` mount** — Claude cannot access `secrets.yaml` or other sensitive HA config files
- **Reduced privileges** — `hassio_role` downgraded from `manager` to `default`
- **Removed HA API access** — `homeassistant_api` and `auth_api` disabled
- **Minimized attack surface** — removed unnecessary Python packages and tools from the container

## Community Tools

Tools built by the community to enhance Claude Terminal:

- **[ha-ws-client-go](https://github.com/schoolboyqueue/home-assistant-blueprints/tree/main/scripts/ha-ws-client-go)** by [@schoolboyqueue](https://github.com/schoolboyqueue) - Lightweight Go CLI for Home Assistant WebSocket API.
- **[Claude Home Assistant Plugins](https://github.com/ESJavadex/claude-homeassistant-plugins)** by [@ESJavadex](https://github.com/ESJavadex) - A collection of Claude Code skills/plugins for Home Assistant.
- **[Claude Terminal Pro](https://github.com/ESJavadex/claude-code-ha)** by [@ESJavadex](https://github.com/ESJavadex) - A fork with additional features.

## Support

If you have any questions or issues with this add-on, please create an issue in this repository.

## Credits

Originally created by [heytcass](https://github.com/heytcass) with the assistance of Claude Code. This fork focuses on security hardening.

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
