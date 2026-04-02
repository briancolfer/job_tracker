# AGENTS.md

## Project Snapshot
- Rails 8.1 monolith (`config/application.rb`) using SQLite and Solid adapters; no separate API service.
- This codebase is currently **CLI-first**: user-facing behavior is in `lib/job_tracker/cli.rb`, invoked by `bin/jt`.
- Web UI is mostly scaffold defaults right now (`config/routes.rb` only exposes `/up`; no job application controllers/views yet).

## Architecture You Should Load Into Context
- Domain center is `JobApplication` (`app/models/job_application.rb`) with `has_many` to `InterviewStage`, `Contact`, and `FollowUp`.
- Status pipeline is enforced via enum in `JobApplication`; terminal statuses are `rejected`, `withdrawn`, `ghosted` and drive `.active`/`.terminal` scopes.
- CLI commands (`list`, `show`, `add`, `update`, `export`, `reminders`) call ActiveRecord directly (no service layer).
- Import path is Rake-based: `lib/tasks/import.rake` reads CSV rows and creates `JobApplication` (+ optional `InterviewStage`).

## Critical Workflows
- Initial setup: `bin/setup` (installs gems, prepares DB, clears logs/tmp, optionally starts dev stack).
- Dev runtime: `bin/dev` -> Foreman -> `Procfile.dev` (`web` + Tailwind watcher).
- CLI runtime: `bin/jt <command>` (boots full Rails environment first).
- Tests: use RSpec (`spec/models/*`, `spec/lib/cli_spec.rb`) with FactoryBot + Faker.
- CI gate sequence lives in `config/ci.rb`: setup, RuboCop, bundler-audit, importmap audit, Brakeman.

## Project-Specific Conventions (Important)
- Keep enum vocabularies synchronized across:
  - `JobApplication` enum (`app/models/job_application.rb`)
  - CLI `STATUSES` list (`lib/job_tracker/cli.rb`)
  - Spec expectations (`spec/models/job_application_spec.rb`, `spec/lib/cli_spec.rb`)
- CLI output text is tested with regex expectations; avoid unnecessary wording churn in user-facing `puts` lines.
- Import mapping is intentionally explicit and permissive: unknown CSV statuses default to `:applied` (`lib/tasks/import.rake`).
- `apply_date` is required at model level; CLI/import code fills defaults when source data is missing/invalid.

## Data and Integration Edges
- SQLite files live in `storage/*.sqlite3` (see `config/database.yml`); production also uses separate cache/queue/cable DBs.
- Production uses Solid Queue + Solid Cache + Solid Cable (see `config/environments/production.rb`, `config/queue.yml`, `config/cable.yml`).
- CSV import expects specific headers (`Job`, `apply date`, `Status`, `Initial phone screen`, etc.) in `import:csv` task.
- CSV export schema is fixed in `CLI#export` header row; changing columns is a behavior change and should update specs.

## Change Guidance for Agents
- Prefer small, model+CLI-aligned changes over introducing new abstraction layers unless duplication forces it.
- When adding/changing statuses or stage types, update model enum, CLI options/help text, import mapping, and specs in one PR.
- For behavior changes in CLI commands, update `spec/lib/cli_spec.rb` first (or in the same patch) to lock output/side effects.
- If adding web features, add routes/controllers/views explicitly; do not assume existing web endpoints beyond `/up`.
- Always act as a TDD expert: write or update failing RSpec examples first, then implement the minimal change needed to make them pass.
