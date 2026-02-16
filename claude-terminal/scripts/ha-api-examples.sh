#!/usr/bin/with-contenv bashio

# Home Assistant API Examples for Claude Terminal
#
# ⚠️  NOTE: This add-on has been security-hardened.
#     homeassistant_api and auth_api are DISABLED.
#     hassio_role is set to "default" (not "manager").
#
#     Most examples below will NOT work unless you re-enable
#     those permissions in config.yaml. This file is kept as
#     a reference only.

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Home Assistant API Examples (Reference Only)       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  This add-on runs with reduced privileges for security."
echo "    homeassistant_api: false"
echo "    auth_api: false"
echo "    hassio_role: default"
echo ""
echo "Most API calls below require elevated permissions."
echo "To use them, edit claude-terminal/config.yaml and re-enable"
echo "the needed permissions (at your own risk)."
echo ""

SUPERVISOR_TOKEN="${SUPERVISOR_TOKEN}"
if [ -z "$SUPERVISOR_TOKEN" ]; then
    echo "Error: Supervisor token not found"
    echo "This script must be run from within a Home Assistant add-on"
    exit 1
fi

echo "Supervisor token is available."
echo ""
echo "Example: Get add-on self info (should work with default role):"
echo ""
curl -s -X GET \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Content-Type: application/json" \
    "http://supervisor/addons/self/info" | jq '.data | {name, version, state}' 2>/dev/null || echo "(failed)"
echo ""
