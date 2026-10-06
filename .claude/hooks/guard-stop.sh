#!/bin/bash
# todo-guard 껍데기 — 미완료나 문체 위반이 남으면 턴 종료를 막는다.
SKILL="$HOME/.claude/skills/todo-guard"
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$SKILL" ] || exit 0

INPUT="$(cat)"

# 이미 이 훅 때문에 멈춘 상태면 다시 막지 않는다. 무한루프 방지.
ACTIVE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("stop_hook_active", False))
except Exception: print(False)')"
[ "$ACTIVE" = "True" ] && exit 0

REASONS=""
TODO_OUT="$(python3 "$SKILL/scripts/todo_check.py" --root "$ROOT" 2>/dev/null)"
[ $? -ne 0 ] && REASONS="$TODO_OUT"

DIRTY="$ROOT/.claude/todo-guard-dirty"
if [ -f "$DIRTY" ]; then
  DOC_OUT="$(python3 "$SKILL/scripts/check_docs.py" --root "$ROOT" --changed 2>/dev/null)"
  if [ $? -ne 0 ]; then
    REASONS="$REASONS
$DOC_OUT"
  fi
  rm -f "$DIRTY"
fi

if [ -n "$(printf '%s' "$REASONS" | tr -d '[:space:]')" ]; then
  python3 - "$REASONS" <<'PY'
import json, sys
print(json.dumps({
    "decision": "block",
    "reason": "todo-guard 가 턴 종료를 막았다.\n\n" + sys.argv[1] +
              "\n\n남은 일을 끝내거나, 하지 않기로 했으면 TODO.md 에서 `- [~]` 로 바꾸고 이유를 적는다. "
              "문체 위반은 해당 줄을 고친다."
}, ensure_ascii=False))
PY
fi
exit 0
