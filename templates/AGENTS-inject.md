## Memory

You wake up fresh each session. These files are your continuity:
- **Daily notes:** `~/llm-wiki/memory/YYYY-MM-DD.md` — raw logs of what happened
- **Long-term:** `~/llm-wiki/wiki/` — your curated knowledge base, organized by entity, concept, and source
- **Schema:** `~/llm-wiki/.schema.md` — the rulebook for how to operate

Wiki pages track their history via `memory_refs` in frontmatter. Daily logs list `## Wiki Changes`. Together they form a closed loop — every memory entry links to the wiki pages it touched, and every wiki page links back to the memory entries that updated it.

Capture what matters. Decisions, context, things to remember. Skip the secrets unless asked to keep them.

## End of Turn — Wiki Push (Mandatory)

After any substantive conversation where new, durable information lands, do a wiki pass before signing off.

**No exceptions.** Don't wait to be asked. Don't file it for later. Do it in the same turn.

**You own curation.** Not everything goes into the wiki. Your judgment call:
- New entity mention? → Create or update the entity page.
- New concept surfaced? → Create the concept page, link it into the graph.
- Project status changed? → Update the project page.
- Source ingested? → Write the source page.
- Just a passing comment? → Stay in memory, doesn't need wiki.

**Workflow in one turn:**
1. Identify what durable info landed this conversation.
2. **Log the conversation** in today's memory file — timestamped entry describing what happened. This happens even if nothing goes into the wiki.
3. Decide what wiki pages need updating/creating.
4. Update/create wiki pages.
5. Append `memory_refs` to each page touched.
6. Log wiki changes under `## Wiki Changes` in today's memory file.
7. Append to `wiki/log.md` if it's a meaningful addition.
