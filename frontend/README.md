# SHURIKAPP frontend

Next.js 16 (App Router) + React 19 + TypeScript.

```bash
cp .env.example .env.local
npm install            # from the repository root (npm workspaces)
npm run dev            # http://localhost:3000
```

| Script | What it does |
|---|---|
| `npm run lint` | ESLint with `eslint-config-next` (core web vitals + TypeScript) |
| `npm run typecheck` | Generates Next route types and runs `tsc --noEmit` |
| `npm run build` | Production build (`output: "standalone"`) |

Docker: `Dockerfile` is the production image (build it from the repository root),
`Dockerfile.dev` is used by `docker-compose.yml`.
