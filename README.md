# LLM Wiki — Persistent Agent Memory System

An OpenClaw skill that gives agents long-term memory across sessions. A structured, file-based knowledge system at `~/llm-wiki/`.

## Companion plugin: [wiki-capture](https://github.com/ThatClassyMelon/wiki-capture-plugin)

The **wiki-capture plugin** handles the auto-capture layer:
- `agent_end` hook — auto-writes `.capture-YYYY-MM-DD.md` raw conversation logs
- `before_prompt_build` hook — injects wiki priorities + recent activity into agent context
- Configurable threshold: `all` | `substantive` | `minimal`

**Plugin captures raw logs → Skill provides structure + workflows + maintenance.** Both together form the complete system.

## Quick Start

**One command:**
```bash
curl -sSL https://raw.githubusercontent.com/ThatClassyMelon/llm-wiki-skill/main/scripts/install.sh | bash
```

That handles everything — clones the wiki-capture plugin, installs the skill, patches `openclaw.json`, bootstraps the wiki structure, and optionally sets up cron jobs. Just restart OpenClaw after.

**Manual install:**
```bash
git clone https://github.com/ThatClassyMelon/llm-wiki-skill.git /tmp/llm-wiki-install
bash /tmp/llm-wiki-install/scripts/install.sh
```

## What's Inside

- **Full rulebook** (`.schema.md`) — directory structure, naming conventions, frontmatter, all workflows
- **Session startup discipline** — forces the agent to read the wiki on every new session
- **Wiki push workflow** — mandatory after substantive conversations
- **Source ingestion pipeline** — articles, social posts, media, tools (4 templates + generic)
- **Lint system** — weekly + monthly maintenance with cron jobs
- **Taxonomy system** — hub-and-spoke model across 5 brain domains
- **Bootstrap script** — one-shot directory + template creation (idempotent)
- **AGENTS.md injection** — appends the startup discipline + wiki push rules to workspace AGENTS.md

## Structure

```
llm-wiki/
  SKILL.md                 — agent instructions
  _meta.json               — skill metadata
  scripts/
    bootstrap.sh           — one-time directory + template setup
    cleanup-empty.sh       — lint: find/remove empty pages
    setup-cron.sh          — maintenance cron jobs
  templates/
    .schema.md             — the full rulebook
    .gitignore             — for the wiki repo
    index.md               — vault root template
    wiki-index.md          — wiki catalog template
    wiki-log.md            — empty changelog
    AGENTS-inject.md       — startup discipline fragment
```
