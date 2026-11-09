# CLAUDE.md

Guidance for Claude Code when working in this repository.

The owner (Juan) speaks Spanish: answer in Spanish unless asked otherwise. He works on
Windows 11 with PowerShell; give commands that run there.

## What this is

SHURIKAPP, a monorepo:

- `backend/` Rails 8.1 API, Ruby 4.0.9, PostgreSQL (Supabase in production), Clerk auth
- `frontend/` Next.js 16 (App Router) + React 19 + TypeScript, npm workspaces from the root
- `docs/` specification of record: read `00`–`03` before designing or changing the data model
- `docs/04-advisory-app-brief.md` decisions for the advisory modules (billing, Colombian tax and
  social security, personal finance) that are being added: read it before architecture work

## Commands

Backend (from `backend/`). On Windows prefix the binstubs with `ruby` (`ruby bin/rubocop`),
because PowerShell cannot run files with a Unix shebang.

```powershell
bundle install
ruby bin/rubocop              # style: rubocop-rails-omakase
ruby bin/brakeman --no-pager  # security static analysis
ruby bin/bundler-audit        # vulnerable gems
docker compose up -d db       # from the repo root: local PostgreSQL 17
$env:RAILS_ENV = "test"; ruby bin/rails db:prepare; bundle exec rspec; Remove-Item Env:RAILS_ENV
```

Frontend (from the repo root):

```powershell
npm install
npm run lint        # ESLint flat config (Next 16 has no `next lint`)
npm run typecheck   # next typegen + tsc --noEmit
npm run build
```

Full stack: `docker compose up --build` (API on :3001, frontend on :3000).

## Conventions

- Ruby style is rubocop-rails-omakase (double quotes, `[ "spaces" ]` inside array brackets).
  Keep `bin/rubocop` clean; CI runs it.
- Tests are RSpec: request specs in `spec/requests`, unit specs mirror `app/` (e.g.
  `spec/services/...`). Never call Clerk or other external services from specs; see
  `spec/support/clerk_token_helpers.rb` for signed test tokens.
- Authenticated endpoints inherit from `Api::V1::BaseController`, which verifies the Clerk
  session token with `Auth::ClerkTokenVerifier` and exposes `current_clerk_user_id`.
- Data model (docs/03): UUID primary keys, every tenant-owned table carries
  `organization_id`, status fields are enums, audit records are immutable.
- Local database settings come from `DB_HOST` / `DB_PORT` / `DB_USERNAME` / `DB_PASSWORD`
  (default host `127.0.0.1`: on Windows `localhost` can reach a native PostgreSQL instead of
  the container). Production uses `DATABASE_URL`. Do not set `DATABASE_URL` locally.
- Never commit `backend/.env` or `frontend/.env.local`; update the `.env.example` files instead.
- `Gemfile.lock` must keep the `x86_64-linux` platform (Docker and CI). After changing gems on
  Windows run `bundle lock --add-platform x86_64-linux`.
- Rules that change with laws or decrees (UVT, minimum wage, tax and contribution rates) are
  data versioned by effective date, never constants in code. See docs/04.

## CI

`.github/workflows/ci.yml` runs on pull requests and pushes to `master`: backend security
(Brakeman, bundler-audit), backend lint (RuboCop), backend tests (RSpec with PostgreSQL) and
frontend lint, types and build. Work on a branch and open a PR to `master`.
