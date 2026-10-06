# Spec Delta

## Purpose

Lets team members discuss a meeting's decisions in place, so questions and answers stay next to the notes they are about.

## ADDED Requirements

### Requirement: Add a comment
<!-- Source: storyboard D-09, D-10 · publish: detail.html -->
`POST /api/meetings/{id}/comments` SHALL let a member of the meeting's team add a comment of 1 to 500 characters and SHALL return `201`. Empty or longer comments SHALL get `400 VALIDATION_ERROR`. Adding a comment SHALL record a `comment_add` activity, and the screen SHALL clear the comment field afterwards.

#### Scenario: Add a comment
- **WHEN** a member posts `결정 2번 일정 확인 부탁드립니다`
- **THEN** the response is `201`, the comment appears at the end of the list, and the field is cleared

#### Scenario: Too long
- **WHEN** a member posts 501 characters
- **THEN** the response is `400 VALIDATION_ERROR`

### Requirement: List comments
<!-- Source: storyboard D-01, D-11 · publish: detail.html -->
`GET /api/meetings/{id}/comments` SHALL return the comments oldest first, each with `id`, `user_id`, `user_name`, `content`, `created_at` and `can_delete`. `can_delete` SHALL be decided by the server: true for the comment's author and the team owner. With no comments, the response SHALL be `200` with an empty list.

#### Scenario: Delete button only where allowed
- **WHEN** a member who is not the owner views comments by themselves and by others
- **THEN** only their own comments have `can_delete` true and show a delete button

#### Scenario: No comments
- **WHEN** a meeting has no comments
- **THEN** the response is `200` with `[]`

### Requirement: Delete a comment
<!-- Source: storyboard D-12 · publish: detail.html -->
`DELETE /api/comments/{id}` SHALL be allowed for the comment's author and the team owner and SHALL return `204`. Others SHALL get `403 FORBIDDEN`.

#### Scenario: Owner removes a comment
- **WHEN** the team owner deletes another member's comment
- **THEN** the response is `204` and the comment is gone

#### Scenario: Someone else's comment
- **WHEN** a member who is not the owner deletes another member's comment
- **THEN** the response is `403 FORBIDDEN`
