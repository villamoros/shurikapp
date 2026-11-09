# SHURIKAPP backend

Rails 8.1 API (Ruby 4.0.3) with PostgreSQL and Clerk authentication.

## Local setup

```bash
cp .env.example .env        # fill in the Clerk values
bundle install
bin/rails db:prepare
bin/dev                     # http://localhost:3001
```

Or, from the repository root, `docker compose up` starts PostgreSQL, the API and the frontend.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/up`, `/api/v1/health` | none | Health check |
| GET | `/api/v1/session` | Clerk token | Returns the Clerk user and session behind the token |

Authenticated controllers inherit from `Api::V1::BaseController`, which verifies the
`Authorization: Bearer <token>` header with `Auth::ClerkTokenVerifier` (RS256, issuer,
expiry and authorized party) and exposes `current_clerk_user_id`.

## Quality checks

```bash
bin/rubocop          # style (rubocop-rails-omakase)
bin/brakeman         # security static analysis
bin/bundler-audit    # known vulnerable gems
bundle exec rspec    # test suite (needs PostgreSQL)
bin/ci               # all of the above, as CI runs them
```

## Configuration

See `.env.example`. In production set `DATABASE_URL` (Supabase, with `sslmode=require`),
`SECRET_KEY_BASE`, `FRONTEND_URL` and the `CLERK_*` variables.

## Docker

- `Dockerfile`: multi-stage production image (non-root, `RAILS_ENV=production`, port 3001).
- `Dockerfile.dev`: development image used by `docker-compose.yml`.
