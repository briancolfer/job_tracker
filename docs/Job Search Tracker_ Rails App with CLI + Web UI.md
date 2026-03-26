# Job Search Tracker: Rails App with CLI + Web UI
## Problem
Replace a sparse, hard-to-maintain CSV with a structured tool that enforces a status pipeline, tracks interview stages with detail, stores contacts and prep notes, sends follow-up reminders, and provides reporting.
## Architecture
Single Rails 8.0.2 app with SQLite. CLI and web UI share the same models and database — no API layer needed.
* **CLI**: Thor-based commands in `lib/tasks/` or a `bin/jt` executable that boots the Rails environment and calls model methods directly. Fast data entry without opening a browser.
* **Web UI**: Rails views + Tailwind for richer browsing, reporting dashboards, and editing. Added after CLI is working.
## Data Model
**JobApplication** (core)
* `company`, `role_title`, `job_type` (string)
* `location`, `remote` (boolean)
* `source` (string: Indeed, LinkedIn, Referral, Cold Call, Recruiter, etc.)
* `status` (enum — see pipeline below)
* `apply_date` (date)
* `job_posting_url` (string)
* `notes` (text)
**InterviewStage** (belongs_to JobApplication)
* `stage_type` (enum: phone_screen, technical_screen, onsite, offer)
* `scheduled_at` (datetime)
* `completed_at` (datetime)
* `outcome` (enum: pending, passed, failed)
* `notes` (text)
**Contact** (belongs_to JobApplication)
* `name`, `role` (recruiter, hiring_manager, interviewer), `email`, `phone`, `linkedin_url`
* `notes` (text)
**FollowUp** (belongs_to JobApplication)
* `due_date` (date)
* `description` (string)
* `completed` (boolean)
## Status Pipeline (enum)
`cold_call` → `applied` → `phone_screen` → `technical_screen` → `onsite` → `offer_received` → `accepted`
Terminal states: `rejected`, `withdrawn`, `ghosted`
## Phases
**Phase 1 — Models + CLI**
1. Generate Rails app (`rails new job_tracker --database=sqlite3 --css=tailwind -T`)
2. Create migrations and models with validations
3. Build Thor CLI (`bin/jt`) with commands: `add`, `list`, `update`, `show`, `reminders`, `export`
4. Import existing CSV via a rake task (`rake import:csv[path/to/file.csv]`)
5. Export to CSV via `bin/jt export` (optional path and status filter)
**Phase 2 — Web UI**
1. Controllers + views for JobApplications (index, show, edit)
2. Pipeline/Kanban-style status view
3. Reporting: applications per week, response rate, funnel by stage
**Phase 3 — Reminders**
1. `bin/jt reminders` CLI command listing overdue follow-ups
2. Optional: daily digest email via letter_opener locally, real mailer in production
## TDD Approach
RSpec for all models (validations, state transitions, associations) and CLI commands. Write tests before implementation at each phase.
## CSV Import
Rake task maps CSV columns to the new schema. Status values are normalized to the enum pipeline. Rows with missing fields default gracefully.
## CSV Export
`bin/jt export` writes all applications to CSV. Supports `--output/-o` for a custom path and `--status/-s` to filter by status. Defaults to `tmp/job_applications_<date>.csv`. Columns: `id, company, role_title, job_type, location, remote, source, status, apply_date, job_posting_url, notes`.
## Deployment & Infrastructure
**Hosting**: Single Droplet on Digital Ocean (minimal specs, ~1 GB RAM).
**Containerization**: Podman for container management.
**Database**: SQLite3 running on the same server.
**Backups**: Weekly backups synced to Mac and home NAS.
**Monitoring**: Basic monitoring; enhanced setup planned.
**Security**: Basic security initially; hardening planned.
**IaC**: Terraform for provisioning the Droplet, firewall rules, DNS, and backup configuration via the `digitalocean/digitalocean` provider.
**Configuration Management**: Ansible for server setup, Podman configuration, and app deployment.
**CI/CD**: GitHub Actions — runs RSpec suite and triggers deployment on merge to `main`.
