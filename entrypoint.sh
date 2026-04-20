#!/usr/bin/env bash
set -euo pipefail

# Prefer screen-like key bindings without interactive prompt
if command -v byobu-ctrl-a >/dev/null; then
  byobu-ctrl-a screen >/dev/null 2>&1 || true
fi

# Optional default Codex runtime policy in agent home
mkdir -p "${HOME}/.codex"
if [ -f "${HOME}/.codex/config.toml" ]; then
  echo "Using existing Codex config at ${HOME}/.codex/config.toml"
else
  tee "${HOME}/.codex/config.toml" >/dev/null <<'EOF'
approval_policy = "never"
sandbox_mode = "danger-full-access"

[projects."/workspace"]
trust_level = "trusted"

model = "gpt-5.4-mini"
model_reasoning_effort = "medium"

[features]
apps = false
EOF
fi

# Optional default Claude Code runtime policy in agent home
mkdir -p "${HOME}/.claude"
if [ -f "${HOME}/.claude/settings.json" ]; then
  echo "Using existing Claude Code config at ${HOME}/.claude/settings.json"
else
  tee "${HOME}/.claude/settings.json" >/dev/null <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "enabledPlugins": {},
  "permissions": {
    "defaultMode": "bypassPermissions",
    "skipDangerousModePermissionPrompt": true
  }
}
EOF
fi

${AGENT_ENGINE} "$@"
