# Proposal

## Why

The Day 1 MeetingNote is a single-user note tool: decisions and to-dos from a meeting stay on the screen of whoever took the notes, and the rest of the team cannot see, track or discuss them. MeetingNote Pro turns it into a tool a logged-in team shares. A recording is split into summary, decisions and to-dos, to-dos are tracked on a kanban board, and comments and an activity log keep the context for people who join later. The full definition is in `docs/MeetingNote Pro_프로그램정의.pdf`; the screens and their 62 states are fixed by the storyboard and the files in `publish/`.

## What Changes

- **Auth**: sign up, log in, JWT valid for 24 hours, bcrypt password hashes, view and edit my profile, log out.
- **Team**: create a team with an `MN-XXXX` invite code, join by code (at most 6 members), member list, regenerate the code and rename the team (owner only).
- **Meeting**: upload an mp3 or wav recording (up to 25MB), transcribe it, split it into summary, decisions and to-dos, create, read, update, delete and search meeting notes.
- **To-do**: kanban board with OPEN, DOING and DONE columns, move cards by dragging or tapping, assign an owner and a due date, delete (owner only).
- **Comment**: comment on a meeting (up to 500 characters), list comments, delete (author or team owner).
- **Activity**: record five kinds of team activity and show the team's and my own activity.
- **Data and API**: 7 database tables and 26 endpoints, all under `/api/`. Every error uses one body shape, `{code, msg}`.
- **Screens**: 6 screens built from the final markup in `publish/`, with colors and component classes taken only from `theme.js`.
- **Developer tooling**: FastAPI's Swagger UI at `/docs` for trying the API in a browser, and a pytest suite that is run and reported after development.
- **Deployment**: one Vercel project serving both frontend and backend, with Neon Postgres from Vercel Storage. The same code runs on SQLite locally.
- **Speech-to-text**: Gemini, decided during explore. The key is read from `STT_API_KEY` in `.env` and never committed.

## Out of Scope

- Recording in the browser. Only file upload is supported.
- Telling speakers apart. The transcript is one block of text.
- Calendar or email integration.
- Roles beyond owner and member.
- Uploads over 25MB, or split uploads.
- Push notifications. Activity is shown on screen only.
- Belonging to more than one team at a time.
- Deleting a team, leaving a team, or removing members.

## Capabilities

### New Capabilities
- `auth`: accounts, login tokens, my profile, and the API error format shared by all endpoints.
- `team`: creating and joining a team by invite code, members, owner-only team settings.
- `meeting`: uploading and transcribing recordings, splitting them into three sections, and managing and searching meeting notes.
- `todo`: to-dos taken from meetings, their status, owner and due date, and the kanban board.
- `comment`: comments on a meeting note.
- `activity`: the record of team activity and how it is shown.

### Modified Capabilities
<!-- None: the project has no existing specs. -->

## Impact

- New `backend/` (FastAPI, SQLAlchemy, 7 tables, 26 endpoints, pytest suite) and `frontend/` (6 screens, `theme.js`, a shared API helper), served from one origin.
- New dependencies: FastAPI, Uvicorn, SQLAlchemy, a Postgres driver, PyJWT, bcrypt, the Google Gen AI SDK, pytest. Tailwind is loaded from its CDN.
- Secrets: `STT_API_KEY` and the JWT signing key come from `.env` locally and from Vercel environment variables when deployed. `.env` and the local SQLite file are git-ignored.
- External services: Gemini API for transcription and splitting, Vercel for hosting, Neon for the deployed database.
