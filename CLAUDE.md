# MeetingNote Pro

회의 녹음을 받아쓰고 요약·결정사항·할 일로 정리하는 풀스택 웹 앱.
설계 문서는 `docs/` (프로그램정의 · 스토리보드 · 디자인시스템), 확정 디자인은 `publish/` 에 있다.
개발은 OpenSpec 네 단계(explore → propose → apply → archive)로 진행한다.

## todo-guard 운영 규칙

이 프로젝트는 todo-guard 훅이 걸려 있다. 아래를 지킨다.

### 작업 누락 방지

- 지시를 받으면 **먼저** `TODO.md` 에 `- [ ]` 로 적는다.
  여러 건이면 여러 줄로 나눈다.
- 한 건을 끝내면 그 줄을 `- [x]` 로 바꾼다.
- 하지 않기로 한 건은 `- [~]` 로 바꾸고 이유를 옆에 적는다. 지우지 않는다.
- 미완료가 남은 채로 턴을 끝내려 하면 훅이 막는다.

### 문서 문체

- 슬라이드·보고서를 쓰기 **전에** `~/.claude/skills/todo-guard/rules/doc-rules.md`
  를 읽고 적용한다.
- 다 쓰면 바뀐 줄을 검사한다.
  `python3 ~/.claude/skills/todo-guard/scripts/check_docs.py --root . --changed`
- 위반이 남으면 훅이 턴 종료를 막는다.
- 검사 대상은 `.md`, `.txt`, `.pptx`. `TODO.md` 와 `CLAUDE.md` 는 검사하지 않는다.
