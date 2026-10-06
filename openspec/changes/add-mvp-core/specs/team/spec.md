# Spec Delta

## Purpose

Lets a small team of up to six people gather under one invite code, see who is in it, and lets the owner manage the team's name and code.

## ADDED Requirements

### Requirement: Create a team
<!-- Source: storyboard F-02, F-01 · publish: team.html -->
A logged-in user with no team SHALL be able to create one through `POST /api/teams` with a name. The response SHALL be `201` with the team's `id`, `name` and `invite_code`. The invite code SHALL have the format `MN-` followed by 4 uppercase letters or digits, and SHALL be unique. The creator SHALL become the team's `owner`. A user who already belongs to a team SHALL get `400 VALIDATION_ERROR`.

#### Scenario: First team
- **WHEN** a user with no team sends `{"name": "기획팀"}` to `POST /api/teams`
- **THEN** the response is `201` with an invite code such as `MN-7K2D`, and the user is the owner

#### Scenario: Already in a team
- **WHEN** a member of a team calls `POST /api/teams`
- **THEN** the response is `400 VALIDATION_ERROR` and no team is created

### Requirement: Users without a team
<!-- Source: storyboard F-02 · publish: team.html -->
`GET /api/teams` SHALL return the teams the user belongs to, which is an empty list or one team. A user with no team SHALL be sent to the team screen, where they can create a team or enter an invite code, and SHALL NOT be able to open the meeting, to-do or profile screens until they have a team.

#### Scenario: Logged in with no team
- **WHEN** a user with no team logs in
- **THEN** the team screen opens with options to create a team or join by code

### Requirement: Join by invite code
<!-- Source: storyboard F-03, F-06 · publish: team.html, login.html -->
`POST /api/teams/join` with an invite code SHALL add the user to that team as a `member` and return `200` with the team. Joining SHALL be recorded as a `member_join` activity. An unknown code SHALL get `404 INVITE_NOT_FOUND`. A team that already has 6 members SHALL get `409 TEAM_FULL`. Joining a team the user is already in SHALL return `200` and change nothing. A user who belongs to a different team SHALL get `400 VALIDATION_ERROR`.

#### Scenario: Valid code
- **WHEN** a user with no team joins with the code of a team that has 3 members
- **THEN** the response is `200`, the team has 4 members, and a `member_join` activity is recorded

#### Scenario: Team is full
- **WHEN** a user joins with the code of a team that has 6 members
- **THEN** the response is `409 TEAM_FULL` and the team still has 6 members

#### Scenario: Joining again
- **WHEN** a member joins their own team again with its code
- **THEN** the response is `200` and the member list does not change

### Requirement: Member list
<!-- Source: storyboard F-01 · publish: team.html -->
`GET /api/teams/{id}/members` SHALL return each member's `id`, `name`, `email`, `role` and `todo_count` (the to-dos assigned to them). Only members of the team SHALL be allowed to see it; others SHALL get `403 FORBIDDEN`.

#### Scenario: Member views the list
- **WHEN** a member calls `GET /api/teams/{id}/members` for their team
- **THEN** every member is listed with their role and number of assigned to-dos

#### Scenario: Outsider
- **WHEN** a user who is not in the team calls it
- **THEN** the response is `403 FORBIDDEN`

### Requirement: Share and regenerate the invite code
<!-- Source: storyboard F-04, F-05, F-08 · publish: team.html -->
The team screen SHALL show the team's single invite code with a copy button. The owner SHALL be able to replace the code through `PUT /api/teams/{id}/code`, which SHALL return `200` with the new code. After that, the old code SHALL NOT work, and existing members SHALL stay in the team. A member who is not the owner SHALL get `403 OWNER_ONLY`.

#### Scenario: Owner regenerates
- **WHEN** the owner regenerates the code `MN-7K2D`
- **THEN** a new code is returned, joining with `MN-7K2D` gets `404 INVITE_NOT_FOUND`, and nobody is removed

#### Scenario: Member tries to regenerate
- **WHEN** a member who is not the owner calls `PUT /api/teams/{id}/code`
- **THEN** the response is `403 OWNER_ONLY` and the code is unchanged

### Requirement: Rename the team
<!-- Source: storyboard F-07, F-08 · publish: team.html -->
The owner SHALL be able to rename the team through `PUT /api/teams/{id}`, which SHALL return `200`. A member who is not the owner SHALL get `403 OWNER_ONLY`, and the screen SHALL show the team settings to members as read-only.

#### Scenario: Owner renames
- **WHEN** the owner renames the team to `디자인팀`
- **THEN** the response is `200` and the new name appears in the header of every screen

#### Scenario: Member tries to rename
- **WHEN** a member who is not the owner calls `PUT /api/teams/{id}`
- **THEN** the response is `403 OWNER_ONLY` and the name is unchanged
