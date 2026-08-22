# Status Updates and JSON API

## Summary

This change adds a fast status-update workflow to the applications list and a
small, versioned JSON API for trusted local integrations. It also makes invalid
enum values normal model validation errors instead of allowing them to raise an
`ArgumentError` during assignment.

The existing full edit form and job-status assignment commands remain available.
The status catalog now has its own database table, while the stored integer
values of existing `JobApplication.status` records remain unchanged.

## Status behavior

`JobApplication.status` remains an integer-backed Rails enum. Its mapping,
display labels, default, and terminal behavior are loaded from the `job_statuses`
database table. The initial codes are created by `bin/rails db:seed`:

```text
cold_call
applied
phone_screen
technical_screen
onsite
offer_received
accepted
rejected
withdrawn
ghosted
job_filled
second_round
on_hold
```

Each catalog entry has a stable integer `value`, a user-facing `label`, and a
`terminal` flag. One entry is marked as the default:

```ruby
JobStatus.find_by(code: "applied").attributes.slice(
  "value", "label", "terminal", "default"
)
```

The enum uses `validate: true`. Assigning an unsupported value therefore
makes the record invalid and adds `Status is not included in the list` to its
errors. This lets both the HTML controller and JSON API report invalid input
without an unhandled enum-assignment exception.

CLI and web output use the configured display label. The underlying code is
still used for filters, CSV export, and JSON updates. CLI job listings show both,
for example `Recruiter Screen (phone_screen)`.

### Updating an existing application's status

An application can be moved to another supported status through any of these
interfaces:

- Applications list: select a status in the row and submit the inline form.
- Full web form: open `/job_applications/:id/edit`.
- CLI: run `bin/jt status ID NEW_STATUS` or `bin/jt update ID --status NEW_STATUS`.
- JSON API: send a `PATCH` request to `/api/v1/job_applications/:id`.

The inline form submits only `job_application[status]` to:

```text
PATCH /job_applications/:id/status
```

On success it redirects to the applications list with `Application status
updated.`. On validation failure it redirects with the model error messages.

### Managing enum codes and labels

Add a status code and label:

```bash
bin/jt status-add final_interview --label "Final Interview"
```

Add a status that should be excluded from active applications:

```bash
bin/jt status-add declined --label "Declined" --terminal
```

Change only the display label:

```bash
bin/jt status-update phone_screen --label "Recruiter Screen"
```

Rename an enum code and optionally change its label:

```bash
bin/jt status-update onsite \
  --new-code panel_interview \
  --label "Panel Interview"
```

Change terminal behavior with `--terminal` or `--no-terminal`:

```bash
bin/jt status-update withdrawn --no-terminal
```

The catalog validates that codes use lowercase `snake_case`, labels are present,
and codes are unique. A new code receives the next unused integer. Renaming a
code retains its existing integer, including when the default status is renamed,
so existing database rows continue to resolve correctly.

Catalog writes are persisted in the database through the `JobStatus` model.
Codes and integer values are unique, and only one status can be the default.

Rails defines enum methods when the model class loads. Label changes are read
immediately, but a newly added or renamed code requires a new CLI invocation or
web process restart. The command prints this reminder after a successful change.

The web selectors and `GET /api/v1/statuses` reflect the model's enum mapping
after restart. Custom statuses use the fallback gray badge unless a specific
class is added to `ApplicationHelper::STATUS_BADGE_CLASSES`.

## JSON API contract

All endpoints are under `/api/v1`.

| Method | Endpoint | Behavior |
|--------|----------|----------|
| `GET` | `/api/v1/job_applications` | Returns every application, ordered by newest apply date first. |
| `GET` | `/api/v1/job_applications/:id` | Returns one application. |
| `PATCH` or `PUT` | `/api/v1/job_applications/:id` | Updates permitted application fields. |
| `GET` | `/api/v1/statuses` | Returns the valid enum keys as a JSON array. |

### Application representation

Application responses contain:

```json
{
  "id": 12,
  "company": "Acme Corp",
  "role_title": "Site Reliability Engineer",
  "job_type": "Full-time",
  "location": "San Francisco, CA",
  "days_in_office": 2,
  "source": "LinkedIn",
  "status": "phone_screen",
  "status_label": "Recruiter Screen",
  "apply_date": "2026-08-10",
  "job_posting_url": "https://example.com/jobs/12",
  "notes": "Recruiter call completed",
  "created_at": "2026-08-10T18:00:00.000Z",
  "updated_at": "2026-08-19T18:00:00.000Z",
  "arrangement": "Hybrid (2 days/week)"
}
```

`status` remains the stable machine-readable enum code while `status_label` is
the configurable wording. `arrangement` is the human-readable value from
`arrangement_label`; the raw `days_in_office` integer is retained for clients
that need structured data.

### Updating an application

Wrap permitted attributes in a `job_application` object:

```bash
curl --request PATCH http://localhost:3001/api/v1/job_applications/12 \
  --header 'Content-Type: application/json' \
  --data '{"job_application":{"status":"phone_screen","notes":"Recruiter call completed"}}'
```

Permitted attributes are:

```text
company
role_title
job_type
location
days_in_office
source
status
apply_date
job_posting_url
notes
```

A successful update returns HTTP `200` with the updated application.

### Errors

An unknown application returns HTTP `404`:

```json
{
  "error": "Job application not found"
}
```

Invalid attributes return HTTP `422` without persisting any of the requested
changes:

```json
{
  "errors": [
    "Company can't be blank",
    "Status is not included in the list"
  ]
}
```

## Scope and security

This API is sufficient for local scripts and trusted read/update integrations.
It is not a public, multi-user API. In particular:

- There is no authentication or authorization.
- The list endpoint is not paginated or filtered.
- API create and delete operations are intentionally not exposed.
- There is no rate limiting or formal compatibility policy beyond the `/v1`
  namespace.

Do not expose these endpoints through ngrok or a public deployment until an
authentication mechanism is added.

## TDD coverage and verification

The change was driven by tests in this order:

1. Catalog examples for adding codes, updating labels, renaming codes while
   preserving integer values, terminal flags, and invalid changes.
2. CLI examples for `statuses`, `status-add`, `status-update`, and configured
   labels in job output.
3. Model examples for catalog-backed enum mappings, labels, and dynamic
   terminal scopes.
4. Request and system examples for exposing configured labels through the API
   and web UI.
5. The minimum catalog, model, CLI, API, and view implementation needed to make
   each new example pass.

Verification at completion:

- RSpec: 205 examples, 0 failures.
- RuboCop: 9 touched Ruby/spec files, no offenses.
- `git diff --check`: clean.
- Brakeman: no findings in the new API code. One pre-existing weak warning
  remains for the stored job-posting URL used by the show-page link.
