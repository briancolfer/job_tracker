# Status Updates and JSON API

## Summary

This change adds a fast status-update workflow to the applications list and a
small, versioned JSON API for trusted local integrations. It also makes invalid
enum values normal model validation errors instead of allowing them to raise an
`ArgumentError` during assignment.

The existing full edit form and CLI remain available. No database migration or
change to the stored integer values of the `JobApplication.status` enum is
included.

## Status behavior

`JobApplication.status` remains an integer-backed Rails enum. The supported
values are:

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
```

The enum now uses `validate: true`. Assigning an unsupported value therefore
makes the record invalid and adds `Status is not included in the list` to its
errors. This lets both the HTML controller and JSON API report invalid input
without an unhandled enum-assignment exception.

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

### Adding a brand-new status definition

Status definitions are not dynamically administered. Adding a new pipeline
status remains a code change. Keep these locations synchronized:

1. Add the enum key with a new, previously unused integer in
   `app/models/job_application.rb`. Never renumber existing values because the
   database stores those integers.
2. Add the value to `JobTracker::CLI::STATUSES` in `lib/job_tracker/cli.rb`.
3. Add or update model and CLI expectations in
   `spec/models/job_application_spec.rb` and `spec/lib/cli_spec.rb`.
4. Add a badge class in `app/helpers/application_helper.rb` if the default gray
   badge is not appropriate.
5. If the status is terminal, add it to `JobApplication::TERMINAL_STATUSES` and
   cover the `active` and `terminal` scopes.
6. If imported CSV text should map to it, update `STATUS_MAP` in
   `lib/tasks/import.rake` and add an import example.
7. Update the valid-status list in `README.md`.

The web selectors and `GET /api/v1/statuses` read directly from the model enum,
so they automatically include new model keys.

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
  "apply_date": "2026-08-10",
  "job_posting_url": "https://example.com/jobs/12",
  "notes": "Recruiter call completed",
  "created_at": "2026-08-10T18:00:00.000Z",
  "updated_at": "2026-08-19T18:00:00.000Z",
  "arrangement": "Hybrid (2 days/week)"
}
```

`arrangement` is the human-readable value from `arrangement_label`; the raw
`days_in_office` integer is retained for clients that need structured data.

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

1. A model example for invalid status validation.
2. Request examples for API list, show, update, validation failure, not found,
   and status discovery.
3. A system example for updating status from the applications list.
4. The minimum model, routes, controllers, and view implementation needed to
   make those examples pass.

Verification at completion:

- RSpec: 183 examples, 0 failures.
- RuboCop: 7 touched Ruby/spec files, no offenses.
- `git diff --check`: clean.
- Brakeman: no findings in the new API code. One pre-existing weak warning
  remains for the stored job-posting URL used by the show-page link.
