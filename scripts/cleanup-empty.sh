#!/bin/bash
# cleanup-empty.sh - Find and trash empty .md files in the wiki.
# Uses `trash` for recoverability (trash > rm).
#
# Usage:
#   ./cleanup-empty.sh            # Dry-run: list what would be trashed
#   ./cleanup-empty.sh --doit     # Actually trash them
#
# Scans:
#   ~/llm-wiki/wiki/         — core wiki pages
#   ~/llm-wiki/              — root-level orphan stubs (entities/, concepts/, projects/)
#   ~/llm-wiki/memory/       — daily notes (rare but possible)
#   ~/llm-wiki/raw/          — raw source captures

WIKI_ROOT="${LLM_WIKI:-$HOME/llm-wiki}"
DOIT=false
[[ "$1" == "--doit" ]] && DOIT=true

EMPTY_FILES=$(find "$WIKI_ROOT" -maxdepth 4 -name '*.md' -empty 2>/dev/null | sort)

if [[ -z "$EMPTY_FILES" ]]; then
  echo "✓ No empty .md files found."
  exit 0
fi

echo "Empty .md files found:"
echo "$EMPTY_FILES"
echo

if $DOIT; then
  echo "Trashing..."
  echo "$EMPTY_FILES" | while read -r f; do
    trash "$f" && echo "  trashed: $f"
  done

  # Clean up now-empty directories (only leaf dirs)
  find "$WIKI_ROOT" -type d -empty 2>/dev/null | while read -r d; do
    # Avoid trashing project roots or special dirs
    basename=$(basename "$d")
    case "$basename" in
      memory|wiki|raw|canvas|scripts|entities|concepts|projects|sources|scratch|.git)
        # Keep structural dirs even if empty
        ;;
      *)
        trash "$d" 2>/dev/null && echo "  removed empty dir: $d"
        ;;
    esac
  done

  echo "✓ Done."
else
  echo "(dry-run — pass --doit to actually trash them)"
fi