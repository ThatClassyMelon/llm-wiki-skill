#!/bin/bash
# llm-wiki one-liner install — clones both repos, configures, bootstraps
#
# curl -sSL https://raw.githubusercontent.com/ThatClassyMelon/llm-wiki-skill/main/scripts/install.sh | bash
# OR
# git clone https://github.com/ThatClassyMelon/llm-wiki-skill.git /tmp/llm-wiki-install
# bash /tmp/llm-wiki-install/scripts/install.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${HOME}/.openclaw/workspace/skills/llm-wiki"
PLUGIN_DIR="${HOME}/.openclaw/extensions/wiki-capture"
CONFIG_FILE="${HOME}/.openclaw/openclaw.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧠 llm-wiki full install${NC}"
echo ""

# ─── Clone plugin ────────────────────────────────────────────────────

if [[ -d "$PLUGIN_DIR" ]]; then
  echo -e "   ${GREEN}✓${NC} wiki-capture plugin already installed"
else
  echo "   Cloning wiki-capture plugin..."
  git clone https://github.com/ThatClassyMelon/wiki-capture-plugin.git "$PLUGIN_DIR" --quiet
  echo -e "   ${GREEN}✓${NC} wiki-capture plugin installed"
fi

# ─── Clone skill (if we're running from the repo, skip) ──────────────

if [[ ! -d "$SKILL_DIR" ]]; then
  if [[ -f "${SCRIPT_DIR}/../SKILL.md" ]]; then
    # Running from cloned repo — copy ourselves
    REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
    cp -r "$REPO_ROOT" "$SKILL_DIR"
    echo -e "   ${GREEN}✓${NC} llm-wiki skill copied from local repo"
  else
    echo "   Cloning llm-wiki skill..."
    git clone https://github.com/ThatClassyMelon/llm-wiki-skill.git "$SKILL_DIR" --quiet
    echo -e "   ${GREEN}✓${NC} llm-wiki skill installed"
  fi
else
  echo -e "   ${GREEN}✓${NC} llm-wiki skill already installed"
fi

# ─── Configure openclaw.json ─────────────────────────────────────────

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "   ${YELLOW}⚠${NC} No openclaw.json found at $CONFIG_FILE — creating minimal config"
  cat > "$CONFIG_FILE" <<'EOF'
{
  "agents": { "defaults": {}, "list": [{ "id": "main", "skills": ["llm-wiki"] }] },
  "skills": { "entries": { "llm-wiki": { "enabled": true } } },
  "plugins": { "entries": {} }
}
EOF
fi

python3 - "$CONFIG_FILE" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
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

# Add to first agent's skills allowlist
agents = config.get("agents", {}).get("list", [])
if not agents:
    config.setdefault("agents", {}).setdefault("list", [])
    config["agents"]["list"].append({"id": "main", "skills": ["llm-wiki"]})
    changed = True
else:
    agent_skills = agents[0].get("skills", [])
    if "llm-wiki" not in agent_skills:
        agent_skills.append("llm-wiki")
        agents[0]["skills"] = agent_skills
        changed = True

if changed:
    with open(sys.argv[1], "w") as f:
        json.dump(config, f, indent=2)
    print("   ✓ openclaw.json updated")
else:
    print("   ✓ openclaw.json already configured")
PYEOF

# ─── Bootstrap wiki structure ────────────────────────────────────────

WIKI_ROOT="${HOME}/llm-wiki"
if [[ -f "${WIKI_ROOT}/.schema.md" ]]; then
  echo -e "   ${GREEN}✓${NC} Wiki already bootstrapped at ${WIKI_ROOT}"
else
  echo "   Bootstrapping wiki structure..."
  bash "${SKILL_DIR}/scripts/bootstrap.sh"
fi

# ─── Cron setup ─────────────────────────────────────────────────────

echo ""
echo -e "   ${YELLOW}Set up maintenance cron jobs? (y/n)${NC} \c"
read -r SETUP_CRON
if [[ "$SETUP_CRON" == "y" || "$SETUP_CRON" == "Y" ]]; then
  bash "${SKILL_DIR}/scripts/setup-cron.sh"
else
  echo "   Skipped. Run later: bash ${SKILL_DIR}/scripts/setup-cron.sh"
fi

# ─── Done ────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}🧠 llm-wiki install complete!${NC}"
echo ""
echo "   Plugin:  ${PLUGIN_DIR}"
echo "   Skill:   ${SKILL_DIR}"
echo "   Wiki:    ${WIKI_ROOT}"
echo ""
echo -e "   ${YELLOW}Restart OpenClaw to activate:${NC}"
echo "   openclaw gateway restart"
echo ""
echo "   Verify capture is working:"
echo "   ls ~/llm-wiki/memory/.capture-*.md"
