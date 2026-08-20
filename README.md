# Job Tracker

A Rails application for tracking job applications through the hiring pipeline.
Supports both a **CLI** (`bin/jt`) for local use and a **Web UI** for remote access via browser.

## Requirements

- Ruby 4.0.3
- Bundler

## Setup

```bash
bin/setup
```

This installs dependencies, prepares the SQLite database, and starts the development server. To set up without starting the server:

```bash
bin/setup --skip-server
```

## CLI Usage

All commands are run via `bin/jt`. Boot time is minimal — Rails loads once per invocation.

### Add an application

```bash
bin/jt add -c "Acme Corp" -r "DevOps Engineer" -S "Indeed" -d 2026-04-23
```

| Flag | Alias | Description |
|------|-------|-------------|
| `--company` | `-c` | Company name (required) |
| `--role` | `-r` | Role title |
| `--job_type` | `-t` | Job type (e.g. Full-time, Contract) |
| `--location` | `-l` | Location |
| `--remote` | | Remote position (sets days_in_office: 0) |
| `--onsite` | | On-site position (sets days_in_office: 5) |
| `--hybrid N` | | Hybrid, N days in office per week 0–5 |
| `--source` | `-S` | Where you found the job (e.g. LinkedIn, Indeed, recruiter, company website) |
| `--status` | `-s` | Initial status (default: `applied`) |
| `--apply_date` | `-d` | Application date in `YYYY-MM-DD` (default: today) |
| `--url` | `-u` | Job posting URL |
| `--notes` | `-n` | Free-text notes |

### List applications

```bash
bin/jt list
bin/jt list --status applied phone_screen
bin/jt list --active
bin/jt list --source Indeed
bin/jt list --after 2026-01-01 --before 2026-06-30
```

| Flag | Alias | Description |
|------|-------|-------------|
| `--status` | `-s` | Filter by one or more statuses |
| `--active` | `-a` | Show only non-terminal applications |
| `--source` | `-S` | Filter by how you found the job |
| `--after` | `-A` | Applied on or after `YYYY-MM-DD` |
| `--before` | `-B` | Applied on or before `YYYY-MM-DD` |

### Show details

```bash
bin/jt show 12
```

Displays company, role, type, location, source, status, apply date, URL, notes, interview stages, contacts, and pending follow-ups.

### Update an application

```bash
bin/jt update 12 --status phone_screen
bin/jt update 12 --source "Company Website"
bin/jt update 12 --role "Senior SRE" --notes "Revised comp range"
```

| Flag | Alias | Description |
|------|-------|-------------|
| `--status` | `-s` | New status |
| `--role` | `-r` | Role title |
| `--source` | `-S` | Where you found the job |
| `--url` | `-u` | Job posting URL |
| `--notes` | `-n` | Notes |

### Update status only

```bash
bin/jt status 12 rejected
```

### List valid statuses

```bash
bin/jt statuses
```

This lists each enum code, its display label, and whether it is terminal.

### Manage status codes and labels

```bash
# Add a new enum value; the next unused integer is assigned automatically
bin/jt status-add final_interview --label "Final Interview"

# Add a terminal enum value
bin/jt status-add declined --label "Declined" --terminal

# Change only the user-facing wording
bin/jt status-update phone_screen --label "Recruiter Screen"

# Rename a code without changing its stored integer value
bin/jt status-update onsite --new-code panel_interview --label "Panel Interview"

# Change terminal behavior
bin/jt status-update withdrawn --no-terminal
```

Status definitions live in `config/job_statuses.yml`. Display-label changes are
read immediately. New or renamed enum codes are available after starting a new
CLI or web process. Existing job records remain valid because renames retain the
same integer value.

Statuses marked `terminal: true` in `config/job_statuses.yml` are excluded from
`--active` filtering.

### Export to CSV

```bash
bin/jt export
bin/jt export --output ~/Desktop/jobs.csv
bin/jt export --status applied
```

Exported columns: `id`, `company`, `role_title`, `job_type`, `location`, `days_in_office`, `source`, `status`, `apply_date`, `job_posting_url`, `notes`.

### Reminders

```bash
bin/jt reminders
```

Shows overdue and today's pending follow-ups across all applications.

## CSV Import

```bash
bin/rails import:csv[path/to/file.csv]
```

Expected headers: `Job`, `apply date`, `Status`, `job type`, `location`, `source`, `link`, `Initial phone screen`, `Notes`.

Unknown status values default to `applied`. A `source` column is imported as-is.

## Running Tests

```bash
RUBYOPT=-W0 bundle exec rspec --no-profile
```

## Web UI

A browser-based interface is available for creating, viewing, editing, and deleting
job applications. It mirrors the data accessible via the CLI.

| Page | URL |
|------|-----|
| All applications | `/` or `/job_applications` |
| Application detail | `/job_applications/:id` |
| New application | `/job_applications/new` |
| Edit application | `/job_applications/:id/edit` |

Each detail page also shows read-only interview stages, contacts, and pending follow-ups.
The applications list includes an inline status selector for fast pipeline updates.

## JSON API

A small versioned API supports read/update integrations:

| Method | URL | Purpose |
|--------|-----|---------|
| `GET` | `/api/v1/job_applications` | List applications |
| `GET` | `/api/v1/job_applications/:id` | Show an application |
| `PATCH` | `/api/v1/job_applications/:id` | Update an application |
| `GET` | `/api/v1/statuses` | List valid status values |

Send updates under a `job_application` JSON key:

```bash
curl --request PATCH http://localhost:3001/api/v1/job_applications/12 \
  --header 'Content-Type: application/json' \
  --data '{"job_application":{"status":"phone_screen"}}'
```

The API has no authentication and is intended for trusted local use. Add authentication
before exposing it through ngrok or deploying it on a public network.

See [Status Updates and JSON API](docs/status-updates-and-json-api.md) for the
complete behavior, API contract, status-extension checklist, and limitations.

## Development Server

```bash
bin/dev
```

Starts the Rails server (port 3001 by default) and Tailwind CSS watcher via Foreman.
Open `http://localhost:3001` to use the Web UI locally.

## Remote Access via ngrok

When `bin/dev` is running, you can expose the app to any device using ngrok.

### One-time setup

```bash
brew install ngrok/ngrok/ngrok
ngrok config add-authtoken <YOUR_NGROK_TOKEN>   # https://dashboard.ngrok.com
```

### Starting a session

**Terminal 1 — Rails server**
```bash
bin/dev
```

**Terminal 2 — ngrok tunnel**
```bash
script/ngrok_start_up.sh
```

ngrok prints a public `https://` URL. Open it on any device to access the Web UI remotely.
To use a different port: `PORT=3000 script/ngrok_start_up.sh`.

### Reserved static domain (optional)

Free ngrok generates a random subdomain each session. To get a stable URL every time,
reserve a domain in the ngrok dashboard and run:

```bash
ngrok http --domain=your-name.ngrok-free.app 3001
```
