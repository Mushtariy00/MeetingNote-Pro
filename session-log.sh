#!/usr/bin/env bash
# 실습 - 세션을 열고 닫은 시각을 작업기록.md 에 적는다. $1 = start | end
#   훅은 그때그때의 작업 폴더에서 도므로 상대 경로를 쓰지 않는다.
ROOT="${CLAUDE_PROJECT_DIR:-${BASH_SOURCE[0]%/*/*/*}}"
LOG="$ROOT/작업기록.md"

[ -f "$LOG" ] || printf '# 작업 기록\n\n| 구분 | 일시 |\n|---|---|\n' > "$LOG"

case "$1" in
  start) printf '| 시작 | %s |\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG" ;;
  end)   printf '| 종료 | %s |\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG" ;;
esac
exit 0
