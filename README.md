# LLM Wiki — Persistent Agent Memory System

An OpenClaw skill that gives agents long-term memory across sessions. A structured, file-based knowledge system at `~/llm-wiki/`.

**What it provides:**
- Full rulebook (`.schema.md`) — directory structure, naming conventions, frontmatter, workflows
- Session startup discipline — forces the agent to read the wiki on every new session
- Wiki push workflow — mandatory after substantive conversations
- Source ingestion pipeline — articles, social posts, media, tools
- Lint system — weekly + monthly maintenance with cron jobs
- Taxonomy system — hub-and-spoke model across 5 brain domains
- Source templates for 4 content types + generic

**One-time setup:**
```bash
bash scripts/bootstrap.sh
```

**Cron jobs (optional):**
```bash
bash scripts/setup-cron.sh
```

**Installation:**
Copy to `~/.openclaw/workspace/skills/llm-wiki/`, then enable in `openclaw.json`:
```json
{
  "skills": {
    "entries": {
      "llm-wiki": { "enabled": true }
    }
  }
}
```

**Structure:**
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
