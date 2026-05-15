---
name: llm-wiki
description: Persistent agent memory system — a structured wiki for long-term knowledge, daily memory logs, source ingestion, cross-referencing, and periodic maintenance. Use when setting up a new project memory system, bootstrapping agent continuity, or needing the wiki workflows (ingest, query, lint, wiki push).
tags: [memory, wiki, knowledge-management, agent-continuity, obsidian]
---

# LLM Wiki — Persistent Agent Memory System

A structured, file-based knowledge system at `~/llm-wiki/` that gives agents long-term memory across sessions.

## Session Startup (Every New Session)

Before doing anything, run this checklist. Do not skip.

1. **Read `~/llm-wiki/.schema.md`** — the schema is the rulebook
2. **Read `~/llm-wiki/wiki/yuri/notes.md`** — lessons learned, mistakes not to repeat
3. **Read `~/llm-wiki/wiki/log.md`** (tail -30) — recent activity
4. **Read `~/llm-wiki/wiki/index.md`** — catalog of everything
5. **Check `~/llm-wiki/memory/`** for today's date (`YYYY-MM-DD.md`). Create if missing.
6. **Scan `~/llm-wiki/wiki/scratch/`** — any WIP needing attention?

## End of Turn — Wiki Push (Mandatory)

After any substantive conversation where durable information lands, do a wiki pass. No exceptions.

1. Identify what durable info landed
2. **Log the conversation** in `memory/YYYY-MM-DD.md` — always, even if nothing goes into wiki
3. Decide what wiki pages need updating/creating
4. Update/create wiki pages
5. Append `memory_refs` to each touched wiki page
6. Log wiki changes under `## Wiki Changes` in today's memory
7. Append to `wiki/log.md` if meaningful

## Memory ↔ Wiki Bridge

Daily logs (`memory/YYYY-MM-DD.md`) link to wiki pages via `## Wiki Changes`. Wiki pages link back to memory entries via `memory_refs` frontmatter. This is a closed loop — every memory entry knows what wiki pages it touched, every wiki page knows which memories updated it.

## Files

All files live in `~/llm-wiki/`.

### `.schema.md`
The full rulebook. Read it every session. Contains directory structure, naming conventions, frontmatter format, all workflow specs (ingest, query, lint, scratch triage), source templates, taxonomy rules, and migration paths.

### `wiki/index.md`
Catalog of every wiki page, organized by domain (Social & Brand, Creative & Culture, Tech & Systems, Personal & Lifestyle, Knowledge Base).

### `wiki/log.md`
Chronological changelog — one-line entries for every meaningful addition.

### `wiki/overview.md`
Top-level synthesis of the entire knowledge base.

### `wiki/yuri/notes.md`
Agent scratchpad — raw, timestamped notes. What was learned, what mistakes not to repeat, meta-insights. Updated after every substantive turn.

### `memory/YYYY-MM-DD.md`
Daily raw log with summary, activity, conversations, and wiki changes.

## Directory Structure

```
~/llm-wiki/
├── .schema.md              # The rulebook
├── .gitignore
├── index.md                # Vault root
├── wiki/
│   ├── concepts/            # Ideas, theories, patterns
│   ├── entities/            # People, places, things
│   ├── projects/            # Codebases, tools, builds
│   ├── sources/             # Ingested source summaries
│   ├── scratch/             # WIP, half-baked thoughts
│   ├── user/                # User-related pages
│   ├── yuri/                # Agent scratchpad
│   ├── index.md             # Content catalog
│   ├── log.md               # Chronological activity log
│   ├── overview.md          # Top-level synthesis
│   ├── archivist-log.md     # Long-form archivist notes
│   └── priorities.md        # Active priorities
├── memory/                  # Daily logs
├── scripts/
│   └── cleanup-empty.sh     # Lint: find and remove empty pages
├── concepts/                # (root-level symlink-friendly)
├── entities/
└── projects/
```

## Workflows

### Ingest
When a source is dropped:
1. Read in full. Discuss with user if needed.
2. Write source page in `wiki/sources/` — summary, key claims, quotes, cross-references.
3. Update/create entity and concept pages the source touches.
4. Update `wiki/overview.md` if the big picture changed.
5. Update `wiki/index.md`.
6. Log in `wiki/log.md`.
7. Write daily memory entry.

### Query
When asked a question:
1. Scan `wiki/index.md` for relevant pages.
2. If insufficient, search wiki directory.
3. Read relevant pages.
4. Synthesize answer with wikilinks.
5. Optionally file the answer back as a new page.

### Lint (Weekly)
- Orphans: pages with 0 inbound wikilinks
- Stale: pages with `updated` > 30 days
- Contradictions: disagreeing pages
- Scratch triage: promote, merge, delete, or keep
- Frontmatter compliance
- memory ↔ wiki bridge spot-checks

### Lint (Monthly Deep Clean)
Everything in weekly plus: full migration check, gap analysis, source refresh, redundancy audit, dead link audit, index rebuild, summary report.

### Scratch Triage
For each `wiki/scratch/` page:
- Polished and useful → promote to appropriate wiki subdir
- Better as part of existing page → merge, delete scratch
- Dead → delete or archive
- Still cooking → add `#wip` tag and `last_touched` date

## Taxonomy

All pages belong to one of five domains:
1. **🧠 Social & Brand** — influence, perception, content
2. **🎨 Creative & Culture** — art, film, music, photography
3. **⚙️ Tech & Systems** — infrastructure, software, AI
4. **🏠 Personal & Lifestyle** — health, habits, mindset
5. **📚 Knowledge Base** — sources, entities, raw material

Hub-and-spoke model: broad hub pages contain main content; narrow spoke pages link up. Pages <150 words merge into parent; sections >500 words promote to spoke.

## Source Templates

Available in `.schema.md` and `templates/`:
- **Article/Blog** — longform content
- **Social Media** — posts, reels, stories
- **Media** — podcasts, videos, interviews
- **Tool/Project** — code projects, services
- **Generic** — anything that doesn't fit

## Maintenance Cron Jobs

| Job | Frequency | What it does |
|-----|-----------|--------------|
| Daily memory upkeep | Daily midnight | Triage recent memory files, promote durable content to wiki |
| Weekly lint | Sunday 3am | Run cleanup-empty.sh, check orphans/staleness |
| Monthly deep clean | 1st of month 3am | Full lint pass, gap analysis, index rebuild |

## Setup

### Companion Plugin (Required)

This skill pairs with the **wiki-capture plugin** (`ThatClassyMelon/wiki-capture-plugin`).
- Plugin: auto-captures conversations to `.capture` files + injects wiki context before replies
- Skill: provides the file structure, templates, workflows, and maintenance cron jobs

Install the plugin first: copy to `~/.openclaw/extensions/wiki-capture/` and enable in `openclaw.json`.

### Bootstrap

Run `scripts/bootstrap.sh` for one-time setup. It creates the directory structure, writes template files, and sets up cron jobs.

The bootstrap is idempotent — safe to run multiple times.
