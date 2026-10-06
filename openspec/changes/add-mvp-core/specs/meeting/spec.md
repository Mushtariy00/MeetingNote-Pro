# Spec Delta

## Purpose

Turns a meeting recording into shared meeting notes: the audio is transcribed, split into summary, decisions and to-dos, and kept where the whole team can find, read, edit and search it.

## ADDED Requirements

### Requirement: Upload and transcribe a recording
<!-- Source: storyboard C-05, C-06, C-07, C-08, C-09 · publish: meetings.html -->
`POST /api/upload` SHALL accept one audio file and return `200` with its transcript as text. It SHALL NOT save a meeting. Only mp3 and wav SHALL be accepted, judged by the file's content rather than its name; anything else SHALL get `415 UNSUPPORTED_MEDIA_TYPE`. Files over 25MB SHALL get `413 PAYLOAD_TOO_LARGE`. Transcription MUST finish within 60 seconds. While it runs, the screen SHALL show progress, and when it finishes, the screen SHALL put the transcript into the new meeting's body field without saving.

#### Scenario: Practice recording
- **WHEN** the 4.19MB file `회의_녹음.wav` is uploaded
- **THEN** the response is `200` with the transcript within 60 seconds, and the body field is filled but nothing is saved

#### Scenario: Video renamed to mp3
- **WHEN** an mp4 video named `meeting.mp3` is uploaded
- **THEN** the response is `415 UNSUPPORTED_MEDIA_TYPE`

#### Scenario: File too large
- **WHEN** a 30MB wav file is uploaded
- **THEN** the response is `413 PAYLOAD_TOO_LARGE`

### Requirement: Save a meeting and split it into three sections
<!-- Source: storyboard C-05, C-10, C-11 · publish: meetings.html -->
`POST /api/teams/{id}/meetings` SHALL create a meeting from a `title`, a meeting time `met_at`, a `body`, and optional `attendees`, and SHALL return `201`. `title`, `met_at` and `body` MUST be present, otherwise the response is `400 VALIDATION_ERROR`. While saving, the system SHALL split the body into a `summary`, a list of decisions, and to-dos, each with what to do, an owner name and a due date when the body states them. Decisions SHALL be stored as lines of text. When the body states no decisions or no to-dos, those SHALL be left empty rather than invented. Saving SHALL record a `meeting_add` activity. After saving, the screen SHALL clear the form so the same meeting is not saved twice.

#### Scenario: Save a transcribed meeting
- **WHEN** a member saves a meeting whose body contains two decisions and three action items
- **THEN** the response is `201`, the meeting has a summary, 2 decisions and 3 to-dos, and a `meeting_add` activity is recorded

#### Scenario: Discussion without decisions
- **WHEN** the body only discusses options and decides nothing
- **THEN** the meeting is saved with no decisions

#### Scenario: Missing body
- **WHEN** a meeting is saved without a body
- **THEN** the response is `400 VALIDATION_ERROR` and nothing is saved

### Requirement: Match to-do owners to team members
<!-- Source: storyboard D-03, E-09 · publish: detail.html, todos.html -->
When a to-do is created from a meeting, its owner name SHALL be matched to a team member, ignoring spaces, so `김 대리` matches the member `김대리`. When the name matches no member, or the body names no owner, the to-do SHALL have no owner. An owner SHALL NOT be guessed. A matched owner SHALL be recorded as a `todo_assign` activity.

#### Scenario: Name written with a space
- **WHEN** the body says `김 대리 가 금요일까지 견적 정리` and the team has a member named `김대리`
- **THEN** the to-do is assigned to `김대리` with the due text `금요일`

#### Scenario: Unknown name
- **WHEN** the body names `최부장`, who is not in the team
- **THEN** the to-do has no owner

### Requirement: Meeting list and search
<!-- Source: storyboard C-01, C-02, C-03, C-04 · publish: meetings.html -->
`GET /api/teams/{id}/meetings` SHALL return the team's meetings newest first by `met_at`. Each item SHALL have `id`, `title`, `met_at`, `attendees`, `summary`, `created_at`, `todo_done_count`, `todo_total_count` and `decision_count`, and SHALL NOT include the body. `?q=` SHALL match the title and attendees only, never the body. `?from=` and `?to=` SHALL limit results to an ISO date range. When nothing matches, the response SHALL be `200` with an empty list, not `404`. The screen SHALL show the meetings as cards, giving the stripes blue, green, orange, purple and red in turn by position in the list.

#### Scenario: Search by attendee
- **WHEN** a member searches `?q=박과장`
- **THEN** only meetings whose title or attendees contain `박과장` are returned

#### Scenario: Word only in the body
- **WHEN** a member searches for a word that appears only in a meeting's body
- **THEN** that meeting is not returned

#### Scenario: No results
- **WHEN** a search matches nothing
- **THEN** the response is `200` with `[]` and the screen shows the empty-result state

#### Scenario: New team
- **WHEN** a team with no meetings opens the list
- **THEN** the screen shows "회의록이 없습니다. 새 회의록을 만들어 보세요"

### Requirement: Meeting detail
<!-- Source: storyboard D-01, D-05, D-06, D-07, D-13 · publish: detail.html -->
`GET /api/meetings/{id}` SHALL return the meeting with its body, decisions and to-dos. The screen SHALL show summary, decisions and to-dos in three columns with the decisions numbered, and the body collapsed until the user expands it. An unknown meeting SHALL get `404 MEETING_NOT_FOUND`, and the screen SHALL return to the list. A meeting of another team SHALL get `403 FORBIDDEN`.

#### Scenario: Open a meeting
- **WHEN** a member opens a meeting with 2 decisions
- **THEN** the screen shows the summary, decisions numbered 1 and 2, the to-dos, and a collapsed body

#### Scenario: Deleted meeting
- **WHEN** a member opens the address of a meeting that was deleted
- **THEN** the response is `404 MEETING_NOT_FOUND` and the list opens

### Requirement: Edit a meeting
<!-- Source: storyboard D-02 · publish: detail.html -->
`PUT /api/meetings/{id}` SHALL let any member of the team change the title, meeting time, attendees and body, and SHALL return `200`.

#### Scenario: Fix the title
- **WHEN** a member changes the title of a meeting
- **THEN** the response is `200` and the new title shows in the detail and the list

### Requirement: Delete a meeting
<!-- Source: storyboard D-08 · publish: detail.html -->
`DELETE /api/meetings/{id}` SHALL be allowed only for the meeting's author and the team owner, and SHALL return `204`. Others SHALL get `403 FORBIDDEN`. Deleting SHALL also delete the meeting's to-dos and comments. Before deleting, the screen SHALL ask for confirmation and say that the to-dos will be deleted too.

#### Scenario: Author deletes
- **WHEN** the author confirms deleting a meeting with 3 to-dos
- **THEN** the response is `204` and the meeting and its 3 to-dos are gone

#### Scenario: Other member tries to delete
- **WHEN** a member who is neither the author nor the owner calls `DELETE /api/meetings/{id}`
- **THEN** the response is `403 FORBIDDEN` and nothing is deleted
