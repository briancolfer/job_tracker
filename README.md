# Job Tracker

A CLI-first Rails application for tracking job applications through the hiring pipeline.

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
| `--remote` | | Remote position flag |
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

Valid values: `cold_call`, `applied`, `phone_screen`, `technical_screen`, `onsite`, `offer_received`, `accepted`, `rejected`, `withdrawn`, `ghosted`.

Terminal statuses (`rejected`, `withdrawn`, `ghosted`) are excluded from `--active` filtering.

### Export to CSV

```bash
bin/jt export
bin/jt export --output ~/Desktop/jobs.csv
bin/jt export --status applied
```

Exported columns: `id`, `company`, `role_title`, `job_type`, `location`, `remote`, `source`, `status`, `apply_date`, `job_posting_url`, `notes`.

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

## Development Server

```bash
bin/dev
```

Starts the Rails server and Tailwind CSS watcher via Foreman.
