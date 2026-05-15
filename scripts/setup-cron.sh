#!/bin/bash
# Setup maintenance cron jobs for the llm-wiki system
# Uses OpenClaw's cron system (not system crontab)
#
# Jobs:
#   - Daily midnight: Wiki maintenance (memory triage, promote to wiki)
#   - Weekly Sunday 3am: Lint pass (cleanup-empty, orphans, staleness)
#   - Monthly 1st 3am: Deep clean (gap analysis, index rebuild)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🕐 Setting up llm-wiki cron jobs..."

# Daily midnight — wiki maintenance
openclaw cron add '{
  "name": "llm-wiki daily maintenance",
  "schedule": { "kind": "cron", "expr": "0 0 * * *", "tz": "America/New_York" },
  "payload": {
    "kind": "agentTurn",
    "message": "Wiki maintenance: scan recent memory files (last 2 days), promote durable content to wiki pages, update cross-references. Run cleanup-empty.sh --doit if there are stale stubs."
  },
  "sessionTarget": "isolated",
  "enabled": true
}' 2>/dev/null && echo "✓ Daily maintenance job created" || echo "⚠ Daily job may already exist"

# Weekly Sunday 3am — lint
openclaw cron add '{
  "name": "llm-wiki weekly lint",
  "schedule": { "kind": "cron", "expr": "0 3 * * 0", "tz": "America/New_York" },
  "payload": {
    "kind": "agentTurn",
    "message": "Wiki lint pass: run ~/llm-wiki/scripts/cleanup-empty.sh, check for orphaned pages (0 inbound wikilinks), flag stale pages (updated >30 days ago), check frontmatter compliance, verify memory_refs on recently-touched pages, triage ~/llm-wiki/wiki/scratch/."
  },
  "sessionTarget": "isolated",
  "enabled": true
}' 2>/dev/null && echo "✓ Weekly lint job created" || echo "⚠ Weekly job may already exist"

# Monthly 1st 3am — deep clean  
openclaw cron add '{
  "name": "llm-wiki monthly deep clean",
  "schedule": { "kind": "cron", "expr": "0 3 1 * *", "tz": "America/New_York" },
  "payload": {
    "kind": "agentTurn",
    "message": "Monthly wiki deep clean: full lint pass, gap analysis (concepts mentioned but lacking pages), source refresh on major pages, redundancy audit (overlapping pages to merge), dead link audit, rebuild ~/llm-wiki/wiki/index.md from scratch, write summary report in ~/llm-wiki/wiki/scratch/lint-report-$(date +%Y-%m).md."
  },
  "sessionTarget": "isolated",
  "enabled": true
}' 2>/dev/null && echo "✓ Monthly deep clean job created" || echo "⚠ Monthly job may already exist"

echo ""
echo "Cron jobs set up. Verify with: openclaw cron list"
