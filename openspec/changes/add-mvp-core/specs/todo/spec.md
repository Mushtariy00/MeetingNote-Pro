# Spec Delta

## Purpose

Tracks the to-dos that come out of meetings on a shared kanban board, so the team can see who owns what, what is late, and what is done.

## ADDED Requirements

### Requirement: To-do lists
<!-- Source: storyboard E-01, E-02, E-12 · publish: todos.html -->
`GET /api/teams/{id}/todos` SHALL return all of the team's to-dos and `GET /api/me/todos` SHALL return only those assigned to the user. Each item SHALL have `id`, `what`, `assignee_id`, `assignee_name`, `due_text`, `status` and `meeting_title`, ordered by status and then by due text. Status SHALL be one of `OPEN`, `DOING` and `DONE`. With no to-dos, the response SHALL be `200` with an empty list.

#### Scenario: My to-dos
- **WHEN** a member with 2 assigned to-dos opens "내 할 일"
- **THEN** exactly those 2 are shown, each with the title of its meeting

#### Scenario: Nothing assigned
- **WHEN** a member with no assigned to-dos opens "내 할 일"
- **THEN** the response is `200` with `[]` and the board shows its empty state

### Requirement: Change a to-do
<!-- Source: storyboard D-03, D-04, E-04, E-05, E-06 · publish: todos.html, detail.html -->
`PUT /api/todos/{id}` SHALL let any member of the team change a to-do's `status`, `assignee_id` and `due_text`, and SHALL return `200` with the updated to-do. Status SHALL be able to move between any two of `OPEN`, `DOING` and `DONE`, including backwards. The owner SHALL be a member of the team or empty. Any other status or owner SHALL get `400 VALIDATION_ERROR`. Setting an owner SHALL record a `todo_assign` activity, and moving to `DONE` SHALL record a `todo_done` activity.

#### Scenario: Move to DOING
- **WHEN** a member sends `{"status": "DOING"}` for an `OPEN` to-do
- **THEN** the response is `200` with status `DOING`

#### Scenario: Move back
- **WHEN** a `DONE` to-do is set back to `OPEN`
- **THEN** the response is `200` with status `OPEN`

#### Scenario: Assign an owner
- **WHEN** a member assigns a to-do with no owner to `이주임`
- **THEN** the response is `200` and a `todo_assign` activity is recorded

#### Scenario: Unknown status
- **WHEN** a member sends `{"status": "LATER"}`
- **THEN** the response is `400 VALIDATION_ERROR`

### Requirement: Delete a to-do
<!-- Source: storyboard E-11, F-08 · publish: todos.html -->
`DELETE /api/todos/{id}` SHALL be allowed only for the team owner and SHALL return `204`. Others SHALL get `403 OWNER_ONLY`. Finished to-dos SHALL NOT be deleted automatically.

#### Scenario: Owner deletes
- **WHEN** the owner deletes a to-do
- **THEN** the response is `204` and it disappears from the board

#### Scenario: Member tries to delete
- **WHEN** a member who is not the owner calls `DELETE /api/todos/{id}`
- **THEN** the response is `403 OWNER_ONLY`

### Requirement: Kanban board interaction
<!-- Source: storyboard E-03, E-04, E-05, N-01 · publish: todos.html -->
The board SHALL show three columns, 대기 (`OPEN`), 진행 (`DOING`) and 완료 (`DONE`). On wide screens, the user SHALL be able to drag a card to another column with mouse or touch: a see-through copy follows the pointer and the target column is outlined while dragging. The status SHALL be saved with one request when the card is dropped, and the card SHALL go back to its column if the request fails. On narrow screens, where the columns stack, tapping a card SHALL show buttons for the three columns instead.

#### Scenario: Drag to done
- **WHEN** a user drags a card from 진행 to 완료 and drops it
- **THEN** exactly one update request is sent and the card stays in 완료

#### Scenario: Failed move
- **WHEN** the update request fails after a drop
- **THEN** the card returns to the column it came from

#### Scenario: Phone width
- **WHEN** the board is 360px wide and the user taps a card
- **THEN** buttons for 대기, 진행 and 완료 appear, and choosing one moves the card

### Requirement: Board filters and overdue marking
<!-- Source: storyboard E-07, E-08, E-09, E-10 · publish: todos.html -->
The board SHALL let the user filter by owner, show only finished to-dos, and see to-dos with no owner, all without another server request. When a to-do's due text is a date that has passed, or says 어제, 지난 주 or 지난 달, the board SHALL mark it with a red stripe, except for to-dos that are `DONE`. Due text that is not a date SHALL never be marked overdue.

#### Scenario: Late to-do
- **WHEN** an `OPEN` to-do has the due text `2026-09-30` and today is 2026-10-06
- **THEN** its card has a red stripe

#### Scenario: Finished late to-do
- **WHEN** a `DONE` to-do has a past due date
- **THEN** its card has no red stripe

#### Scenario: Filter by owner
- **WHEN** the user picks `박과장` in the owner filter
- **THEN** only 박과장's cards are shown and no request is sent
