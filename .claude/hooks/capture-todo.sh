#!/bin/bash
# todo-guard 껍데기 — 받은 지시를 TODO.md 에 적으라고 일깨운다.
SKILL="$HOME/.claude/skills/todo-guard"
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$SKILL" ] || exit 0

python3 - "$ROOT" <<'PY'
import json, sys, os
root = sys.argv[1]
todo = os.path.join(root, "TODO.md")
msg = ("todo-guard: 이번 지시에서 할 일을 TODO.md 에 `- [ ]` 로 먼저 적는다. "
       "여러 건이면 여러 줄로 나눈다. 끝낸 줄은 `- [x]`, "
       "하지 않기로 한 줄은 `- [~]` 로 바꾸고 이유를 적는다.")
if not os.path.exists(todo):
    msg += " TODO.md 가 없으면 만든다."
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": msg
}}, ensure_ascii=False))
PY
exit 0
