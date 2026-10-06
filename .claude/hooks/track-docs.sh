#!/bin/bash
# todo-guard 껍데기 — 문서를 고치면 검사 대상으로 표시한다.
SKILL="$HOME/.claude/skills/todo-guard"
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -f "$SKILL/scripts/track_doc.py" ] || exit 0
python3 "$SKILL/scripts/track_doc.py" --root "$ROOT"
exit 0
