# Design

## Context

The project has no code yet. It holds the design documents in `docs/` (program definition, storyboard, design system) and the final markup in `publish/` (6 screens, `components.html`, `index.html` and `theme.js`). Those documents fix the stack, the 7 tables, the 26 endpoints, the error codes and every screen state, and the specs in this change restate them as requirements. This design records how to build them and the decisions the documents leave open. See `proposal.md` for the motivation.

Fixed by the documents: FastAPI with SQLAlchemy, SQLite locally and Neon Postgres when deployed, Vanilla JS with the Tailwind CDN, JWT plus bcrypt, one Vercel project for frontend and backend. Decided in explore: Gemini for speech-to-text, Swagger UI on, pytest after development, one acceptance item for a person at the end of `tasks.md`.

## Goals / Non-Goals

**Goals:**
- One codebase that runs locally with `uvicorn` and on Vercel unchanged, switching databases only by whether `DATABASE_URL` is set.
- Screens that are the `publish/` markup with behavior attached, not a redesign.
- Every endpoint testable from Swagger UI and covered by pytest with transcription mocked, so tests need no network and no key.

**Non-Goals:**
- Database migrations. Tables are created on startup. There is no data to migrate yet.
- A frontend build step, framework or bundler.
- Background jobs or queues. Transcription runs inside the upload request.

## Decisions

### Folder layout
```
backend/
  app/
    main.py          FastAPI app, error handlers, static files, Swagger
    config.py        settings from environment / .env
    database.py      engine and session (SQLite or Postgres)
    models.py        7 tables
    schemas.py       request and response models
    security.py      bcrypt, JWT, current-user dependency
    stt.py           Gemini transcription and three-part split
    activity.py      recording activities and building their sentences
    routers/         auth, teams, meetings, todos, comments, activities
  tests/             pytest suite
frontend/            login, meetings, detail, todos, team, profile .html,
                     index.html, theme.js, api.js
requirements.txt  pyproject.toml  .env.example
```
- *Why:* routers by capability mirror the 6 specs, so a failing test points at one file. The frontend is a plain folder because the definition requires static files served by the backend.

### Database: SQLAlchemy with one switch
`database.py` uses `DATABASE_URL` when it is set and `sqlite:///./meetingnote.db` otherwise. A `postgres://` or `postgresql://` URL from Vercel is rewritten to `postgresql+psycopg://` for the psycopg 3 driver. Tables are created with `Base.metadata.create_all` at startup.
- *Alternative:* Alembic migrations. Rejected for the MVP: there is one schema version and no existing data.
- `meetings.decisions` is one TEXT column with one decision per line, as the definition specifies. `decision_count` counts non-empty lines.
- `memberships` has a unique `user_id`, which enforces one team per user in the database as well as in code.
- Deleting a meeting deletes its to-dos and comments through ORM cascades.

### Time
All timestamps are stored and returned as UTC ISO 8601 strings ending in `Z`. The screens convert to local time for display.
- *Why:* the Day 2 course warns about times showing 9 hours off. Storing naive local times on a UTC server is the usual cause.

### Login tokens and passwords
- PyJWT with HS256. The signing key comes from `JWT_SECRET`, `exp` is set to 24 hours after issue, and nothing refreshes it.
- bcrypt with its default cost. That makes sign-up and log-in slower than other endpoints, which the definition allows (250ms instead of 100ms).
- A FastAPI dependency reads `Authorization: Bearer <token>`. A missing, malformed or expired token all give `401 TOKEN_EXPIRED`, because the screen does the same thing in each case: it clears the token and goes to the login screen.
- The frontend keeps the token in `localStorage`, which the definition's assumptions accept.

### One error format
An `ApiError(status, code, msg)` exception and handlers in `main.py` turn every error into `{code, msg}`:
- `ApiError` → its own status and code.
- FastAPI request validation errors → `400 VALIDATION_ERROR`.
- Unknown routes → `404 NOT_FOUND`.
- *Why:* FastAPI's default error bodies are `{"detail": ...}`, which breaks the spec's error format.

### Permissions
A helper loads the resource and the user's membership and raises the right code:
- not a member of the team → `403 FORBIDDEN`
- owner-only actions (rename the team, regenerate the code, delete a to-do) → `403 OWNER_ONLY`
- delete a meeting or comment → author or owner, otherwise `403 FORBIDDEN`

### Invite codes
`MN-` plus 4 characters from `A-Z` and `0-9`, generated with `secrets.choice` and regenerated on the rare collision with the unique index. Joining a full team (6 members) gives `409 TEAM_FULL`.

### Speech-to-text with Gemini
`stt.py` uses the Google Gen AI SDK (`google-genai`), with the key from `STT_API_KEY` and the model from `STT_MODEL`. The default is a current Flash model, and its exact name is confirmed against Gemini's model list when the backend is built. It does two calls with the same model, as the definition requires:
1. **Transcribe**: send the audio and ask for a plain Korean transcript.
2. **Split**: send the transcript and ask for JSON with `summary` (string), `decisions` (list of strings) and `todos` (list of `{what, assignee, due_text}`), enforced with the SDK's response schema. The prompt tells it to leave a list empty and an assignee null when the text does not state one.

Transcription happens in `POST /api/upload`. The split happens when the meeting is saved, so the user can correct the transcript first.
- *Alternative:* OpenAI Whisper plus a separate model for the split. Rejected in explore: two providers, and the definition asks for the same model.
- Audio up to about 15MB is sent inline. Larger files go through the Gemini Files API, which handles the rest of the 25MB limit.
- Gemini can briefly return `503 UNAVAILABLE` on the free tier. The client retries up to 3 times with a short backoff, and the total time is capped by a timeout so the 60-second limit holds.
- The split prompt and its JSON schema are kept in `stt.py`, so tests can replace both calls with fixed responses.

### Upload checks
`POST /api/upload` reads the file in chunks and stops with `413 PAYLOAD_TOO_LARGE` once it passes 25MB. The type is decided from the first bytes, not the name: `RIFF....WAVE` is wav, and an `ID3` tag or an MPEG frame sync (`0xFF 0xE?`) is mp3. Anything else gives `415 UNSUPPORTED_MEDIA_TYPE`.

### Matching to-do owners
Names from the split are compared with member names after removing all whitespace, so `김 대리` matches `김대리`. If that fails, the name is checked again with a trailing job title (대리, 주임, 과장, 부장, 팀장) removed from both sides. No match leaves the owner empty. Matched owners record `todo_assign`.

### Activity sentences
`activity.py` records the five kinds and builds the `text` sentence when the activity is listed, for example `김대리 님이 「주간 회의」 회의록을 올렸습니다`. Activities keep `target` (the meeting title or to-do text at the time) so the sentence still reads after the target is deleted.

### Frontend: publish markup plus `api.js`
Each screen is copied from `publish/`. The state bar (`window.stateBar`) and the sample-data scripts are removed, and the real data is loaded through `api.js`:
- `api.js` wraps `fetch`: relative `/api/...` paths, `Authorization` header from `localStorage`, and JSON parsing. On `401 TOKEN_EXPIRED`, it clears the token and opens `/login.html`. Other errors are thrown as `{code, msg}` for the screen to show.
- `theme.js` is copied unchanged. Screens use only `window.UI`, `STRIPE`, `LABEL` and `notice`, with no new colors, corner radii, `!important`, or inline styles. The one exception is the upload progress bar's width, which is set from script as in the publish file.
- All text is set with `textContent` or escaped, never as raw HTML from data.
- The kanban drag keeps the publish file's pointer-event code. It sends one `PUT` on drop and moves the card back if the request fails.
- *Why:* the definition says the publish files are the specification, and the storyboard's 62 states are already built in them.

### Serving and Swagger
`main.py` mounts the API routers under `/api`, adds `GET /api/health`, and mounts `frontend/` with `StaticFiles(html=True)` at `/`, so pages are `/login.html` and so on. Swagger UI stays at FastAPI's default `/docs`. Locally everything runs on one origin: `uvicorn app.main:app --port 8799` from `backend/`. CORS only allows origins listed in `CORS_ORIGINS`, as the definition requires, and same-origin requests do not need it.

### Tests
pytest with FastAPI's `TestClient`. Each test gets a fresh SQLite database. `stt.py` is replaced with a stub that returns a fixed transcript and split. There is one test file per capability plus `test_errors.py` for the shared error format, permission codes and upload limits. The target is zero failures, not a number of tests.

### Deployment
- A separate deploy folder holds only `backend/`, `frontend/`, `requirements.txt` and `pyproject.toml`, with `[tool.vercel]` naming the FastAPI app as the entrypoint. `.env`, the SQLite file, tests and `docs/` stay out.
- Vercel project `meetingnote-pro` with the FastAPI preset. Neon is added from Vercel Storage, which sets `DATABASE_URL` automatically. `STT_API_KEY`, `STT_MODEL`, `JWT_SECRET` and `CORS_ORIGINS` are set as Vercel environment variables.
- After deploying, the eight API scenarios from the course are run with curl against the deployed URL, and a status-code table is reported.

## Risks / Trade-offs

- [Vercel limits a function's request body to about 4.5MB, so uploads over that fail with Vercel's own `413` before reaching the app's 25MB check (Day 2 slide 7-16)] → The 4.19MB practice file fits. The 25MB limit stays in the spec and the local app, and this gap is reported in the deployment check. Fixing it, for example with direct-to-storage uploads, is a later change.
- [SQLite cannot be used on Vercel: each request may run in a fresh environment, so written files are lost] → `DATABASE_URL` from Neon is required in production. The deploy check confirms the app is connected to Postgres, not the SQLite fallback.
- [A package used locally may be missing from `requirements.txt`, which only shows up in the deployed app] → Deploy from the separate folder and rerun the API scenarios on the deployed URL. Day 2 slide 7-17 shows exactly this failure.
- [Transcription can approach the 60-second limit, and the serverless function's own time limit] → Set the function's maximum duration above 60 seconds in the Vercel config, keep the client timeout at 60 seconds, and report a timeout as an error the screen can show.
- [The model can invent owners or decisions] → The prompt and schema allow empty lists and null owners, owner names must match a member, and the screen lets the user edit everything.
- [Free-tier Gemini returns `503` under load] → Retry with backoff, then report the failure so the user can try again.
- [Tailwind's CDN build is meant for development] → Accepted, as in the definition. Moving to a compiled stylesheet is a later change.

## Open Questions

- The exact Gemini model name for `STT_MODEL`. It is confirmed against the available model list when building `stt.py` and can be changed through the environment variable without changing specs or tasks.
