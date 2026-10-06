# Spec Delta

## Purpose

Keeps a record of what happened in the team, who did it and when, so a leader can follow the week and a newcomer can catch up.

## ADDED Requirements

### Requirement: Recorded activity kinds
<!-- Source: storyboard F-01, J-06 · publish: team.html -->
The system SHALL record an activity with its actor, time and target for exactly five kinds of event: `meeting_add` (a meeting is saved), `todo_assign` (a to-do gets an owner), `todo_done` (a to-do moves to `DONE`), `comment_add` (a comment is added) and `member_join` (someone joins the team). No other kind SHALL be recorded. Profile changes SHALL NOT be recorded.

#### Scenario: Only the five kinds
- **WHEN** a member saves a meeting, renames themselves, and adds a comment
- **THEN** exactly two activities are recorded, `meeting_add` and `comment_add`

### Requirement: Team activity
<!-- Source: storyboard F-01 · publish: team.html -->
`GET /api/teams/{id}/activities` SHALL return the team's 50 most recent activities, newest first. Each item SHALL have `id`, `kind`, `actor_name`, `text` and `created_at`, where `text` is a finished sentence written by the server that the screen shows as is. Only team members SHALL be allowed to see it; others SHALL get `403 FORBIDDEN`. The screen SHALL color each item's stripe by kind: `meeting_add` blue, `todo_assign` orange, `todo_done` green, and `comment_add` and `member_join` purple.

#### Scenario: Recent activity
- **WHEN** a team has 70 activities and a member opens the team screen
- **THEN** the 50 newest are shown, newest first, each with its sentence and a stripe in its kind's color

### Requirement: My activity
<!-- Source: storyboard J-01, J-07 · publish: profile.html -->
`GET /api/me/activities` SHALL return the activities the user performed, newest first, in the same item shape. With none, the response SHALL be `200` with an empty list and the profile screen SHALL show its empty state.

#### Scenario: Just joined
- **WHEN** a user who has only joined the team opens their profile
- **THEN** the list shows their single `member_join` activity

#### Scenario: No activity
- **WHEN** a user with no activities calls `GET /api/me/activities`
- **THEN** the response is `200` with `[]`
