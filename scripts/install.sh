#!/usr/bin/env bash
# llm-wiki one-liner install — clones both repos, configures, bootstraps
#
# curl -sSL https://raw.githubusercontent.com/ThatClassyMelon/llm-wiki-skill/main/scripts/install.sh | bash
# OR:  bash install.sh

set -euo pipefail

# ─── Detect mode (piped curl vs local script) ────────────────────────
IS_PIPED=false
if [[ "${BASH_SOURCE[0]:-}" == /dev/fd/* ]] || [[ "${BASH_SOURCE[0]:-}" == */fd/* ]] || [[ "$0" == "bash" || "$0" == "/bin/bash" || "$0" == "/usr/bin/bash" ]]; then
  IS_PIPED=true
fi

IS_LOCAL_CLONE=false
REPO_ROOT=""
if [[ "$IS_PIPED" == false ]] && [[ -f "${BASH_SOURCE[0]:-$0}" ]]; then
  SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/$(basename "${BASH_SOURCE[0]:-$0}")"
  REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." 2>/dev/null && pwd)"
  if [[ -f "${REPO_ROOT}/SKILL.md" ]]; then
    IS_LOCAL_CLONE=true
  fi
fi

# ─── Preflight checks ─────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

fail() { echo -e "   ${RED}✗${NC} $1"; exit 1; }

HOME="${HOME:-$(echo ~ 2>/dev/null || echo '')}"
if [[ -z "$HOME" || "$HOME" == "~" ]]; then
  fail "Cannot determine HOME directory. Set \$HOME and retry."
fi

if ! command -v git &>/dev/null; then
  fail "git is required. Install it and retry."
fi

PYTHON=""
for py in python3 python; do
  if command -v "$py" &>/dev/null; then "$py" -c "import json" 2>/dev/null && PYTHON="$py" && break; fi
done
if [[ -z "$PYTHON" ]]; then
  echo -e "   ${YELLOW}⚠${NC} No python3 with json support — config patching will be skipped"
fi

# ─── Paths ────────────────────────────────────────────────────────────

SKILL_DIR="${HOME}/.openclaw/workspace/skills/llm-wiki"
PLUGIN_DIR="${HOME}/.openclaw/extensions/wiki-capture"
CONFIG_FILE="${HOME}/.openclaw/openclaw.json"
WIKI_ROOT="${HOME}/llm-wiki"

echo -e "${CYAN}🧠 llm-wiki full install${NC}"
echo "   HOME:     ${HOME}"
echo ""

# ─── Clone plugin ────────────────────────────────────────────────────

if [[ -d "$PLUGIN_DIR" ]] && [[ -f "${PLUGIN_DIR}/index.js" ]]; then
  echo -e "   ${GREEN}✓${NC} wiki-capture plugin already installed"
else
  echo "   Cloning wiki-capture plugin..."
  mkdir -p "$(dirname "$PLUGIN_DIR")"
  if git clone https://github.com/ThatClassyMelon/wiki-capture-plugin.git "$PLUGIN_DIR" --quiet 2>/dev/null; then
    echo -e "   ${GREEN}✓${NC} wiki-capture plugin installed"
  else
    echo -e "   ${YELLOW}⚠${NC} Could not clone wiki-capture-plugin (network issue?)"
  fi
fi

# ─── Clone skill ─────────────────────────────────────────────────────

if [[ -d "$SKILL_DIR" ]] && [[ -f "${SKILL_DIR}/SKILL.md" ]]; then
  echo -e "   ${GREEN}✓${NC} llm-wiki skill already installed"
elif [[ "$IS_LOCAL_CLONE" == true ]] && [[ -n "$REPO_ROOT" ]]; then
  echo "   Installing from local repo..."
  mkdir -p "$(dirname "$SKILL_DIR")"
  cp -r "$REPO_ROOT" "$SKILL_DIR"
  echo -e "   ${GREEN}✓${NC} llm-wiki skill copied from ${REPO_ROOT}"
else
  echo "   Cloning llm-wiki skill..."
  mkdir -p "$(dirname "$SKILL_DIR")"
  if git clone https://github.com/ThatClassyMelon/llm-wiki-skill.git "$SKILL_DIR" --quiet 2>/dev/null; then
    echo -e "   ${GREEN}✓${NC} llm-wiki skill installed"
  else
    fail "Could not clone llm-wiki-skill. Check network and retry."
  fi
fi

# ─── Configure openclaw.json ─────────────────────────────────────────

if [[ -z "$PYTHON" ]]; then
  echo -e "   ${YELLOW}⚠${NC} Skipping openclaw.json config (no python3)"
elif [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "   ${YELLOW}⚠${NC} No openclaw.json found — creating minimal config"
  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat > "$CONFIG_FILE" <<'EOFCONFIG'
{
  "agents": { "defaults": {}, "list": [{ "id": "main", "skills": ["llm-wiki"] }] },
  "skills": { "entries": { "llm-wiki": { "enabled": true } } },
  "plugins": { "entries": {} }
}
EOFCONFIG
  echo -e "   ${GREEN}✓${NC} Created default openclaw.json"
else
  # Backup before modifying
  BACKUP="${CONFIG_FILE}.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG_FILE" "$BACKUP"

  "$PYTHON" - "$CONFIG_FILE" <<'PYEOF'
import json, sys

config_path = sys.argv[1]
with open(config_path) as f:
    config = json.load(f)

changed = False

# Plugin entry
config.setdefault("plugins", {}).setdefault("entries", {})
if "wiki-capture" not in config["plugins"]["entries"]:
    config["plugins"]["entries"]["wiki-capture"] = {
        "enabled": True,
        "config": {
            "autoRecall": True,
            "autoCapture": True,
            "captureThreshold": "all"
        },
        "hooks": {"allowConversationAccess": True}
    }
    changed = True

# Skill entry
config.setdefault("skills", {}).setdefault("entries", {})
if "llm-wiki" not in config["skills"]["entries"]:
    config["skills"]["entries"]["llm-wiki"] = {"enabled": True}
    changed = True

# Add to every agent's skills allowlist (handles multi-agent configs)
agents = config.get("agents", {}).get("list", [])
if not agents:
    config.setdefault("agents", {}).setdefault("list", [])
    config["agents"]["list"].append({"id": "main", "skills": ["llm-wiki"]})
    changed = True
else:
    for agent in agents:
        skills = agent.get("skills", [])
        if not isinstance(skills, list):
            skills = []
            agent["skills"] = skills
        if "llm-wiki" not in skills:
            skills.append("llm-wiki")
            changed = True

if changed:
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)
    print("   ✓ openclaw.json updated")
else:
    print("   ✓ openclaw.json already configured")
PYEOF

  if [[ $? -eq 0 ]]; then
    echo -e "   ${GREEN}✓${NC} Backup saved: ${BACKUP}"
  else
    echo -e "   ${RED}✗${NC} Config patch failed. Restoring backup..."
    cp "$BACKUP" "$CONFIG_FILE"
    fail "Config patching failed. openclaw.json restored from backup."
  fi
fi

# ─── Bootstrap wiki structure ────────────────────────────────────────

if [[ -f "${WIKI_ROOT}/.schema.md" ]]; then
  echo -e "   ${GREEN}✓${NC} Wiki already bootstrapped at ${WIKI_ROOT}"
else
  BOOTSTRAP_SCRIPT="${SKILL_DIR}/scripts/bootstrap.sh"
  if [[ ! -f "$BOOTSTRAP_SCRIPT" ]]; then
    echo -e "   ${YELLOW}⚠${NC} bootstrap.sh not found"
  else
    echo "   Bootstrapping wiki structure..."
    bash "$BOOTSTRAP_SCRIPT"
  fi
fi

# ─── Cron setup ─────────────────────────────────────────────────────

echo ""
CRON_SCRIPT="${SKILL_DIR}/scripts/setup-cron.sh"
if [[ -f "$CRON_SCRIPT" ]]; then
  if [[ -t 0 ]]; then
    echo -e "   ${YELLOW}Set up maintenance cron jobs? (y/n)${NC} \c"
    read -r SETUP_CRON
    [[ "$SETUP_CRON" == "y" || "$SETUP_CRON" == "Y" ]] && bash "$CRON_SCRIPT" 2>/dev/null || echo "   Skipped. Run later: bash ${CRON_SCRIPT}"
  else
    echo "   (non-interactive — run bash ${CRON_SCRIPT} after restart to set up cron)"
  fi
fi

# ─── Done ────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}🧠 llm-wiki install complete!${NC}"
echo ""
echo "   Plugin:  ${PLUGIN_DIR}"
echo "   Skill:   ${SKILL_DIR}"
echo "   Wiki:    ${WIKI_ROOT}"
echo "   Config:  ${CONFIG_FILE}"

if [[ ! -f "${PLUGIN_DIR}/index.js" ]]; then
  echo -e "   ${YELLOW}⚠ Plugin files missing — wiki-capture clone may have failed${NC}"
fi

echo ""
echo -e "   ${YELLOW}Restart OpenClaw to activate:${NC}"
echo "   openclaw gateway restart"
echo ""
echo "   Verify capture: ls ~/llm-wiki/memory/.capture-*.md (after a few messages)"
