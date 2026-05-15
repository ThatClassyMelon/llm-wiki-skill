#!/bin/bash
# llm-wiki bootstrap — one-time setup for the persistent agent memory system
#
# Idempotent: safe to run multiple times.
# Creates directory structure, writes template files, sets up cron jobs.
#
# Usage: bash bootstrap.sh [--force]

set -euo pipefail
FORCE="${1:-}"

WIKI_ROOT="${HOME}/llm-wiki"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES="${SCRIPT_DIR}/../templates"

echo "🧠 llm-wiki bootstrap"
echo "   Wiki root: ${WIKI_ROOT}"

# ─── Directory Structure ──────────────────────────────────────────────

mkdir -p "${WIKI_ROOT}/wiki/concepts"
mkdir -p "${WIKI_ROOT}/wiki/entities"
mkdir -p "${WIKI_ROOT}/wiki/projects"
mkdir -p "${WIKI_ROOT}/wiki/sources"
mkdir -p "${WIKI_ROOT}/wiki/scratch"
mkdir -p "${WIKI_ROOT}/wiki/user"
mkdir -p "${WIKI_ROOT}/wiki/yuri"
mkdir -p "${WIKI_ROOT}/memory"
mkdir -p "${WIKI_ROOT}/scripts"

echo "✓ Directory structure created"

# ─── Template Files ───────────────────────────────────────────────────

write_template() {
  local dest="${WIKI_ROOT}/${1}"
  local src="${2}"
  if [[ -f "$dest" ]]; then
    if [[ "$FORCE" == "--force" ]]; then
      echo "   Overwriting: $dest"
      cp "$src" "$dest"
    else
      echo "   Skipping (exists): $dest"
    fi
  else
    cp "$src" "$dest"
    echo "   Created: $dest"
  fi
}

# Schema (the rulebook)
write_template ".schema.md" "${TEMPLATES}/.schema.md"

# Gitignore
write_template ".gitignore" "${TEMPLATES}/.gitignore"

# Root vault index
write_template "index.md" "${TEMPLATES}/index.md"

# Wiki pages
write_template "wiki/index.md" "${TEMPLATES}/wiki-index.md"
write_template "wiki/log.md" "${TEMPLATES}/wiki-log.md"

# Cleanup script
write_template "scripts/cleanup-empty.sh" "${SCRIPT_DIR}/cleanup-empty.sh"
chmod +x "${WIKI_ROOT}/scripts/cleanup-empty.sh"

# ─── Wiki Boot Files (only if they don't exist) ────────────────────────

create_if_missing() {
  local dest="${WIKI_ROOT}/${1}"
  if [[ -f "$dest" ]]; then
    echo "   Skipping (exists): $dest"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  cat > "$dest" <<HEREDOC
${2}
HEREDOC
  echo "   Created: $dest"
}

create_if_missing "wiki/overview.md" '# Wiki Overview

Your knowledge base at a glance. Update this as the big picture evolves.

## Active Projects

(projects you are actively working on)

## Current Focus

(what matters right now)

## Key Insights

(durable learnings worth remembering)

## Open Questions

(things you are still figuring out)
'

create_if_missing "wiki/archivist-log.md" '# Archivist Log

Long-form notes on major updates, structural decisions, and meta-level observations about the wiki itself.

---
'

create_if_missing "wiki/priorities.md" '# Priorities

## Now

- (what needs attention immediately)

## Next

- (upcoming work)

## Later

- (someday/maybe)

## Done

<!-- Move completed items here -->
'

create_if_missing "wiki/yuri/notes.md" "# Yuri's Notes — Lessons Learned

Raw, timestamped scratchpad. Updated after every substantive turn. Not curated — just quick notes to future-me.

## Preferences & Habits
- (what I've learned about my human)

## Mistakes Made
- (things I got wrong and shouldn't repeat)

## Meta Insights
- (how to work better)

---
"

create_if_missing "memory/$(date +%F).md" "# $(date +%F)

## Summary
Wiki bootstrapped via llm-wiki skill.

## Activity
- $(date '+%H:%M'): llm-wiki bootstrap complete

## Conversations
- (none yet)

## Wiki Changes
- Created: wiki bootstrapped
"

create_if_missing ".obsidian/app.json" '{
  "promptDelete": false,
  "alwaysUpdateLinks": true
}'

echo ""
echo "🧠 llm-wiki bootstrap complete!"
echo "   Wiki root: ${WIKI_ROOT}"
echo ""
echo "Injecting AGENTS.md startup discipline..."

# ─── Inject into workspace AGENTS.md ─────────────────────────────────
AGENTS_MD="${HOME}/.openclaw/workspace/AGENTS.md"
INJECT="${TEMPLATES}/AGENTS-inject.md"

if [[ -f "$AGENTS_MD" ]] && [[ -f "$INJECT" ]]; then
  if grep -q "Wiki Push (Mandatory)" "$AGENTS_MD"; then
    echo "   Already injected — skipping"
  else
    # Append the injection fragment
    echo "" >> "$AGENTS_MD"
    cat "$INJECT" >> "$AGENTS_MD"
    echo "   ✓ AGENTS.md updated with wiki push + memory discipline"
  fi
else
  echo "   ⚠ AGENTS.md not found at $AGENTS_MD — skipping"
  echo "   Manually append templates/AGENTS-inject.md to your workspace AGENTS.md"
fi

echo ""
echo "Next steps for your agent:"
echo "   1. Read ~/llm-wiki/.schema.md"
echo "   2. Read ~/llm-wiki/wiki/yuri/notes.md"
echo "   3. Explore wiki/ and start logging"
echo ""
echo "To set up maintenance cron jobs, run:"
echo "   scripts/setup-cron.sh"
