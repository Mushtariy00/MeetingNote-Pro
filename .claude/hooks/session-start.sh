#!/bin/bash
# todo-guard 껍데기 — 세션을 열 때 TODO.md 의 미완료를 알린다.
SKILL="$HOME/.claude/skills/todo-guard"
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -f "$SKILL/scripts/todo_check.py" ] || exit 0

OUT="$(python3 "$SKILL/scripts/todo_check.py" --root "$ROOT" 2>/dev/null)"
if [ $? -ne 0 ]; then
  python3 - "$OUT" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "todo-guard: TODO.md 에 미완료가 남아 있다.\n" + sys.argv[1]
}}, ensure_ascii=False))
PY
fi
exit 0
