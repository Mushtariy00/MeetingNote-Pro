# Spec Delta

## Purpose

Lets people create an account, log in, stay logged in for a day, and manage their own name and password. It also fixes the error format every MeetingNote Pro endpoint uses.

## ADDED Requirements

### Requirement: Common API conventions
<!-- Source: storyboard I-01, H-01 · publish: all screens -->
Every endpoint SHALL live under the `/api/` path prefix. Every error response SHALL have the body `{"code": "<CODE>", "msg": "<message>"}`, where `code` is one of `EMAIL_INVALID`, `PASSWORD_TOO_WEAK`, `TOKEN_EXPIRED`, `INVITE_NOT_FOUND`, `MEETING_NOT_FOUND`, `EMAIL_DUPLICATED`, `TEAM_FULL`, `PAYLOAD_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE`, `INVALID_CREDENTIALS`, `FORBIDDEN`, `OWNER_ONLY`, `VALIDATION_ERROR` or `NOT_FOUND`. Timestamps in responses SHALL be ISO 8601 in UTC. Every endpoint except sign-up and log-in SHALL require a valid login token.

#### Scenario: Error body shape
- **WHEN** any endpoint rejects a request
- **THEN** the response body has exactly the fields `code` and `msg`, and `code` is one of the listed values

#### Scenario: Request without a token
- **WHEN** a client calls `GET /api/teams` with no login token
- **THEN** the response is `401` with code `TOKEN_EXPIRED`

### Requirement: Sign up
<!-- Source: storyboard B-05, B-06, B-07, B-08, B-09, B-10 · publish: login.html -->
The system SHALL create an account from an email, a password and a name through `POST /api/auth/signup`, and SHALL return `201` with the account (`id`, `name`, `email`) and a login token. Emails MUST be unique. The password MUST be at least 8 characters. The screen SHALL check the email format and password length before sending, SHALL NOT show errors while the user is still typing, and SHALL lock the submit button while the request is in progress.

#### Scenario: New account
- **WHEN** an unused email, the name `Kim` and an 8-character password are sent to `POST /api/auth/signup`
- **THEN** the response is `201` with the account and a token, and the screen stores the token

#### Scenario: Email already registered
- **WHEN** someone signs up with an email that already has an account
- **THEN** the response is `409 EMAIL_DUPLICATED` and the existing account's password is unchanged

#### Scenario: Malformed email
- **WHEN** the email is `kim@`
- **THEN** the response is `400 EMAIL_INVALID` and the screen shows "올바른 이메일 형식이 아닙니다"

#### Scenario: Short password
- **WHEN** the password has 7 characters
- **THEN** the response is `400 PASSWORD_TOO_WEAK` and the screen shows "8자 이상 입력해 주세요"

### Requirement: Sign up with an invite code
<!-- Source: storyboard B-05, B-11, F-03 · publish: login.html, team.html -->
The sign-up screen SHALL show an optional invite code field. When a code is entered, the screen SHALL join the team with it right after the account is created. If the code is not found, the account SHALL still exist and the user SHALL be sent to the team screen with the message "초대코드를 찾을 수 없습니다".

#### Scenario: Valid code at sign-up
- **WHEN** a person signs up with the invite code `MN-7K2D` of a team with 3 members
- **THEN** the account is created, the person becomes a member of that team, and the meeting list opens

#### Scenario: Unknown code at sign-up
- **WHEN** a person signs up with the invite code `MN-0000`, which no team has
- **THEN** the account is created, the join fails with `404 INVITE_NOT_FOUND`, and the team screen opens

### Requirement: Password storage
<!-- Source: storyboard B-05 · publish: login.html -->
Passwords MUST be stored only as bcrypt hashes. No response SHALL ever contain a password or its hash.

#### Scenario: Stored value is a hash
- **WHEN** an account is created with the password `secret123`
- **THEN** the stored value is a bcrypt hash, not `secret123`, and the sign-up response does not contain it

### Requirement: Log in
<!-- Source: storyboard B-01, B-02, B-04 · publish: login.html -->
The system SHALL return `200` with a login token through `POST /api/auth/login` when the email and password match an account. For a wrong password or an unknown email, it SHALL return the same `401 INVALID_CREDENTIALS`, so the response does not reveal whether the email exists. After logging in, the screen SHALL store the token and open the meeting list, or the team screen if the user has no team.

#### Scenario: Correct credentials
- **WHEN** a registered email and its password are sent to `POST /api/auth/login`
- **THEN** the response is `200` with a token

#### Scenario: Wrong password and unknown email look the same
- **WHEN** one request uses a registered email with a wrong password and another uses an unregistered email
- **THEN** both responses are `401 INVALID_CREDENTIALS` with the same message, "이메일 또는 비밀번호가 올바르지 않습니다"

### Requirement: Token lifetime
<!-- Source: storyboard B-03 · publish: login.html -->
A login token SHALL be valid for 24 hours from when it was issued and SHALL NOT be refreshed. A request with an expired, malformed or missing token SHALL get `401 TOKEN_EXPIRED`. When the screen gets that response, it SHALL delete the stored token and open the login screen with "세션이 만료되었습니다".

#### Scenario: Expired token
- **WHEN** a client calls `GET /api/auth/me` with a token issued 25 hours ago
- **THEN** the response is `401 TOKEN_EXPIRED` and the screen returns to login with the expiry message

### Requirement: My profile
<!-- Source: storyboard J-01, J-02, J-03, J-04, J-05, J-06 · publish: profile.html -->
`GET /api/auth/me` SHALL return the user's `id`, `name`, `email` and `role` in their team (`owner`, `member`, or `null` with no team). `PUT /api/auth/me` SHALL change the name, the password, or both. The email SHALL NOT be changeable. A new password MUST be at least 8 characters, otherwise the response is `400 PASSWORD_TOO_WEAK`. The screen SHALL check that the two new-password fields match before sending, and SHALL lock the save button while saving. Profile changes SHALL NOT be recorded as team activity.

#### Scenario: Change the name only
- **WHEN** the user sends only a new name to `PUT /api/auth/me`
- **THEN** the response is `200`, the name changes, and the old password still works

#### Scenario: Passwords do not match
- **WHEN** the two new-password fields differ and the user clicks save
- **THEN** the screen shows the mismatch and sends nothing to the server

#### Scenario: Weak new password
- **WHEN** the new password has 5 characters
- **THEN** the response is `400 PASSWORD_TOO_WEAK`

### Requirement: Log out
<!-- Source: storyboard B-01 · publish: meetings.html -->
`POST /api/auth/logout` SHALL return `200`. Tokens are stateless, so the server SHALL NOT keep a block list. The screen SHALL delete the stored token and open the login screen.

#### Scenario: Log out
- **WHEN** the user clicks log out
- **THEN** the response is `200`, the stored token is gone, and the login screen opens
