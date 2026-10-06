# Tasks

Work through the groups in order. Each group is one stage of the course's 5-stage workflow (backend, backend tests, frontend, frontend check, deploy), and each stage is committed when it is done.

## 1. Stage 1 - Backend

- [ ] 1.1 Create `requirements.txt` (fastapi, uvicorn, sqlalchemy, psycopg[binary], pyjwt, bcrypt, google-genai, python-multipart, python-dotenv, pytest, httpx), `.env.example` listing `STT_API_KEY`, `STT_MODEL`, `JWT_SECRET`, `CORS_ORIGINS` and `DATABASE_URL` with no values, and `backend/app/config.py`; verify that `pip install -r requirements.txt` succeeds and `.env` is still git-ignored
- [ ] 1.2 Add `database.py` (SQLite by default, `DATABASE_URL` rewritten to `postgresql+psycopg://` when set) and `models.py` with the 7 tables, the unique `memberships.user_id`, and cascades from meetings to to-dos and comments; verify that starting the app creates `meetingnote.db` with exactly the 7 tables
- [ ] 1.3 Add `main.py` with the `ApiError` type and handlers that turn all errors into `{code, msg}`, `GET /api/health`, Swagger UI at `/docs`, CORS from `CORS_ORIGINS`, and `frontend/` served at `/`; verify that `/docs` loads, `/api/health` returns 200, and an unknown `/api/...` path returns `404 {"code": "NOT_FOUND", ...}`
- [ ] 1.4 Add `security.py` (bcrypt, 24-hour HS256 JWT, current-user dependency giving `401 TOKEN_EXPIRED`) and the 5 auth endpoints; verify in Swagger that sign-up, log-in, `GET`/`PUT /api/auth/me` and log-out follow `specs/auth/spec.md`, including `409 EMAIL_DUPLICATED`, `400 PASSWORD_TOO_WEAK` and `401 INVALID_CREDENTIALS`
- [ ] 1.5 Add the permission helper and the 6 team endpoints with `MN-XXXX` codes, the 6-member limit, idempotent re-join and owner-only rename and code regeneration; verify in Swagger the `404 INVITE_NOT_FOUND`, `409 TEAM_FULL` and `403 OWNER_ONLY` cases
- [ ] 1.6 Add `activity.py` (the 5 kinds, `target` kept, server-built sentences) and the 2 activity endpoints (latest 50, newest first); verify that creating and joining a team shows a `member_join` sentence in `GET /api/teams/{id}/activities`
- [ ] 1.7 Add `stt.py`: confirm a current Gemini Flash model name and set it as the `STT_MODEL` default, then implement transcription (inline up to about 15MB, Files API above that) and the JSON split with empty lists and null owners allowed, plus retry on `503` within a 60-second limit; verify with `.env` holding a real key that `회의_녹음.wav` produces a transcript and a split
- [ ] 1.8 Add the 6 meeting endpoints: upload with the 25MB limit and content-based mp3/wav check, create with the split and owner matching that ignores spaces, list with `q`/`from`/`to`, counts and no body, detail, edit, and delete by author or owner with cascade; verify in Swagger every scenario in `specs/meeting/spec.md` that does not need the screen
- [ ] 1.9 Add the 4 to-do endpoints with status in any direction, owner limited to team members, `todo_assign`/`todo_done` activities, and owner-only delete; verify in Swagger the status moves, `400 VALIDATION_ERROR` for `LATER`, and `403 OWNER_ONLY` on delete by a member
- [ ] 1.10 Add the 3 comment endpoints with the 500-character limit, oldest-first order, server-decided `can_delete`, and delete by author or owner; verify in Swagger that `can_delete` differs between the owner and another member
- [ ] 1.11 Count the `/api/` operations in Swagger and confirm there are 26 plus `/api/health`, then commit stage 1

## 2. Stage 2 - Backend tests

- [ ] 2.1 Add `backend/tests/conftest.py` with a fresh SQLite database per test, a `TestClient`, helpers for users, teams and tokens, and a stub that replaces both Gemini calls with fixed output; verify that `python -m pytest` runs and collects with no network access and no `STT_API_KEY`
- [ ] 2.2 Write `test_auth.py`, `test_team.py` and `test_activity.py` covering every scenario in their specs, including token expiry with a token issued 25 hours ago and the rule that profile changes record no activity; verify they pass
- [ ] 2.3 Write `test_meeting.py`, `test_todo.py` and `test_comment.py` covering every scenario in their specs, including body-only search not matching, delete cascades, owner matching for `김 대리` and status moves in both directions; verify they pass
- [ ] 2.4 Write `test_errors.py` for the `{code, msg}` shape on every error code, the permission matrix (`FORBIDDEN` and `OWNER_ONLY`), `415` for an mp4 renamed to `.mp3`, and `413` for a file over 25MB; verify it passes
- [ ] 2.5 Run the whole suite, report a table of files and passed/failed counts with 0 failures, fix anything that fails, then commit stage 2

## 3. Stage 3 - Frontend

- [ ] 3.1 Copy `publish/theme.js` to `frontend/theme.js` unchanged and add `frontend/api.js` (relative `/api` paths, bearer token from `localStorage`, `{code, msg}` errors, redirect to `/login.html` on `401 TOKEN_EXPIRED`); verify that `diff publish/theme.js frontend/theme.js` shows no difference
- [ ] 3.2 Build `login.html` from the publish file without the state bar, wiring log-in, sign-up with the optional invite code, client-side email and password checks, the locked button while sending, and the redirect to meetings or the team screen; verify the B-01 to B-11 states in the browser
- [ ] 3.3 Build `meetings.html`: list with the rotating stripe colors, search and date range, empty and no-result states, new meeting form, upload with progress, transcript into the body, save, and form reset; verify the C-01 to C-11 states
- [ ] 3.4 Build `detail.html`: three columns with numbered decisions, collapsed body, edit, delete confirmation, owner and due date on to-dos, status changes, comments with delete only where `can_delete` is true, and the not-found redirect; verify the D-01 to D-13 states
- [ ] 3.5 Build `todos.html` from the publish file's pointer-event board: my and team views, one `PUT` per drop with rollback on failure, tap-to-choose on narrow screens, owner filter, finished-only view, unassigned cards, overdue red stripe, owner-only delete; verify the E-01 to E-12 states
- [ ] 3.6 Build `team.html` (no-team state with create and join, code copy and regenerate, members with to-do counts, rename, read-only for members, activity list colored by kind) and `profile.html` (name and password change, mismatch check, my to-dos, my activity, empty state); verify the F-01 to F-08 and J-01 to J-07 states
- [ ] 3.7 Build `frontend/index.html` as the entry page that opens meetings when logged in and login otherwise, check that no screen adds colors, corner radii, `!important` or inline styles beyond the progress bar, then commit stage 3

## 4. Stage 4 - Frontend check

- [ ] 4.1 Start the server on port 8799, run the eight API scenarios with curl (sign up, log in, create team, join by invite code, upload a recording and check the three sections, save a meeting, move a to-do's status, `403` on a forbidden action), and report each request's status code and response JSON in a table
- [ ] 4.2 Create the demo members 김대리, 이주임 and 박과장 in one team, and verify that a to-do naming `김 대리` is assigned to 김대리
- [ ] 4.3 Upload `gachon10:06_openspec/실습소재/회의_녹음.wav` through the meetings screen and verify that the saved meeting shows a summary, decisions and to-dos with owners
- [ ] 4.4 Verify that uploading an mp4 shows the `415` state and a file over 25MB shows the `413` state
- [ ] 4.5 At 360px width, verify that the meeting list, detail and kanban screens have no horizontal scroll and no cut-off text, that the browser console has no errors on any screen, then commit stage 4

## 5. Stage 5 - Deploy

- [ ] 5.1 Check that the Vercel CLI is installed and logged in, create the `meetingnote-pro` project with the FastAPI preset, and add Neon from Vercel Storage; verify that `DATABASE_URL` appears in the project's environment variables
- [ ] 5.2 Make a separate deploy folder containing only `backend/`, `frontend/`, `requirements.txt` and `pyproject.toml` with `[tool.vercel]` naming the app entrypoint and a function duration above 60 seconds; verify that it contains no `.env`, `*.db`, `tests/` or `docs/`
- [ ] 5.3 Set `STT_API_KEY`, `STT_MODEL`, `JWT_SECRET` and `CORS_ORIGINS` as Vercel environment variables, link the deploy folder to `meetingnote-pro`, and deploy; verify that `https://<project>.vercel.app/api/health` returns 200 and the data goes to Neon, not SQLite
- [ ] 5.4 Rerun the eight API scenarios with curl against the deployed URL, report a status-code table, find the cause of each failure (for example a dependency missing from `requirements.txt`), fix it, and redeploy until all pass
- [ ] 5.5 Upload a file between 4.5MB and 25MB to the deployed app and record in the report that Vercel rejects it before the app's limit, as noted in `design.md`; then commit stage 5

## 6. Acceptance (checked by a person)

- [ ] 6.1 On the deployed URL, from both a computer and a phone, a person signs up, creates a team, has a second account join with the invite code, uploads `회의_녹음.wav`, confirms that the summary, decisions and to-dos make sense for the recording, moves one to-do to 완료 on the board, and sees that move in the team's activity list
