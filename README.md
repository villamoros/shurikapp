# SHURIKAPP v1

Monorepo for the SHURIKAPP platform.

## Stack

- Backend: Rails 8.1 API (Ruby 4.0.9)
- Frontend: Next.js 16 + React 19 + TypeScript
- Auth: Clerk, verified directly by the backend API (`Auth::ClerkTokenVerifier`)
- Database: PostgreSQL (Supabase in production, a local container in development)
- Deploy: Docker, separate images for backend and frontend

## Structure

- `backend/` Rails API — see `backend/README.md`
- `frontend/` Next.js app — see `frontend/README.md`
- `docs/` product and technical specification
- `.github/` CI (backend security, lint and tests; frontend lint, types and build) and Dependabot

## Run locally with Docker

```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env.local
docker compose up --build
```

- API: http://localhost:3001/api/v1/health
- Frontend: http://localhost:3000

## Production images

```bash
docker build -t shurikapp-backend ./backend
docker build -f frontend/Dockerfile -t shurikapp-frontend .
```
