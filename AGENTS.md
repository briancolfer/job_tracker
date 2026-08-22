# AGENTS.md

## Project Snapshot
- Rails 8.1 monolith (`config/application.rb`) using SQLite and Solid adapters; the JSON API is implemented inside the monolith.
- This codebase is currently **CLI-first**: user-facing behavior is in `lib/job_tracker/cli.rb`, invoked by `bin/jt`.
- A minimal job application web UI and namespaced `/api/v1` read/update endpoints complement the CLI.

## Architecture You Should Load Into Context
- Domain center is `JobApplication` (`app/models/job_application.rb`) with `has_many` to `InterviewStage`, `Contact`, and `FollowUp`.
- The integer-backed status enum, display labels, default, and terminal behavior are loaded from the `job_statuses` table through `JobStatus`.
- CLI commands (`list`, `show`, `add`, `update`, `export`, `reminders`) call ActiveRecord directly (no service layer); `statuses`, `status-add`, and `status-update` manage the status catalog.
- Import path is Rake-based: `lib/tasks/import.rake` reads CSV rows and creates `JobApplication` (+ optional `InterviewStage`).

## Critical Workflows
- Initial setup: `bin/setup` (installs gems, prepares DB, clears logs/tmp, optionally starts dev stack).
- Dev runtime: `bin/dev` -> Foreman -> `Procfile.dev` (`web` + Tailwind watcher).
- CLI runtime: `bin/jt <command>` (boots full Rails environment first).
- Tests: use RSpec (`spec/models/*`, `spec/lib/cli_spec.rb`, `spec/db/seeds_spec.rb`) with FactoryBot + Faker.
- CI gate sequence lives in `config/ci.rb`: setup, RuboCop, bundler-audit, importmap audit, Brakeman.

## Project-Specific Conventions (Important)
- Treat the `job_statuses` table as the status source of truth. Never renumber an existing status value; renames must retain the stored integer so existing records remain valid.
- New or renamed status codes require a new Rails/CLI process because Rails defines enum methods at boot. Display-label changes are read live.
- Keep status catalog behavior covered across `spec/models/job_status_spec.rb`, `spec/models/job_application_spec.rb`, `spec/db/seeds_spec.rb`, and `spec/lib/cli_spec.rb`.
- CLI output text is tested with regex expectations; avoid unnecessary wording churn in user-facing `puts` lines.
- Import mapping is intentionally explicit and permissive: unknown CSV statuses default to `:applied` (`lib/tasks/import.rake`).
- `apply_date` is required at model level; CLI/import code fills defaults when source data is missing/invalid.

## Work Arrangement Field
The `remote: boolean` column is being replaced by `days_in_office: integer` (0=remote, 1–4=hybrid, 5=on-site, nil=unknown).

### Data Model
- `days_in_office` integer, nullable. Validated: inclusion in `0..5`, nil allowed.
- Migration maps `remote: true → 0`, `remote: false → 5`, `remote: nil → nil`, then drops the `remote` column.
- Model helpers: `remote?` (`== 0`), `hybrid?` (1–4), `onsite?` (`== 5`), `arrangement_label` (returns human string).
- `arrangement_label` returns: `"Remote"`, `"Hybrid (N days/week)"`, `"On-site (5 days/week)"`, or `"Unknown"` when nil.

### CLI Flags (`add` and `update`)
- `--remote` (boolean flag) → sets `days_in_office: 0`
- `--onsite` (boolean flag) → sets `days_in_office: 5`
- `--hybrid N` (integer flag, 0–5) → sets `days_in_office: N`; 0 and 5 are silently treated as remote/onsite
- These three flags are **mutually exclusive** — passing more than one must produce a clear error message.

### CLI `show` Output
- Keep the `Location:` line (without the old `(remote)` annotation).
- Add a new `Arrangement:` line using `arrangement_label`; always shown (displays `"Unknown"` when nil).

### CLI `list` Filter
- Add `--arrangement` filter accepting named labels (`remote`, `hybrid`, `onsite`) or raw integers (`0`–`5`).
- `hybrid` matches `days_in_office IN (1, 2, 3, 4)`; `remote` matches 0; `onsite` matches 5.
- Configurable list columns are **out of scope** here — tracked as a separate feature.

### CSV Export
- The `remote` header is renamed to `days_in_office`; value is the raw integer or blank for nil.

### CSV Import
- Reads an optional `days_in_office` header; accepts integer values `0`–`5` only; blank/missing → nil.

### TDD Order for This Change
1. Model spec: `days_in_office` validation, helper methods.
2. Migration: add column, backfill, drop `remote`.
3. CLI spec (`add`/`update`): new flags, mutual-exclusivity error.
4. CLI spec (`show`): `Arrangement:` line presence and formatting.
5. CLI spec (`list`): `--arrangement` filter behavior.
6. CSV export spec: renamed header and integer value.
7. CSV import spec: `days_in_office` column round-trip.

## Data and Integration Edges
- SQLite files live in `storage/*.sqlite3` (see `config/database.yml`); production also uses separate cache/queue/cable DBs.
- Production uses Solid Queue + Solid Cache + Solid Cable (see `config/environments/production.rb`, `config/queue.yml`, `config/cable.yml`).
- CSV import expects specific headers (`Job`, `apply date`, `Status`, `Initial phone screen`, etc.) in `import:csv` task.
- CSV export schema is fixed in `CLI#export` header row; changing columns is a behavior change and should update specs.

## Change Guidance for Agents
- Prefer small, model+CLI-aligned changes over introducing new abstraction layers unless duplication forces it.
- When changing seeded status behavior, update `db/seeds.rb`, model/CLI behavior, import mapping when relevant, and specs in one PR.
- For behavior changes in CLI commands, update `spec/lib/cli_spec.rb` first (or in the same patch) to lock output/side effects.
- If adding web features, add routes/controllers/views explicitly; do not assume existing web endpoints beyond `/up`.
- Always act as a TDD expert: write or update failing RSpec examples first, then implement the minimal change needed to make them pass.
