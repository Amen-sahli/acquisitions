# Acquisitions API

Express.js API with authentication, backed by [Neon](https://neon.com) Postgres (serverless). The project is Dockerized so the same codebase runs against a local Neon proxy in development and against Neon Cloud in production.

## Architecture

| Environment | Database                     | Config file            | Compose file                  |
| ----------- | ---------------------------- | ---------------------- | ----------------------------- |
| Development | Neon Local (Docker proxy)    | `.env.development`     | `docker-compose.dev.yml`      |
| Production  | Neon Cloud (serverless DB)   | `.env.production`      | `docker-compose.prod.yml`     |

The app connects to Postgres through the Neon serverless driver (`@neondatabase/serverless` over HTTP). `src/config/database.js` detects whether `DATABASE_URL` points at a local proxy (any host that is not `*.neon.tech`) and, if so, configures the driver to talk to the local HTTP endpoint (`http://<host>:<port>/sql`). This happens automatically — no manual config switching.

## Prerequisites

- Docker (with Docker Compose v2)
- A Neon account and project. You need:
  - `NEON_API_KEY` — create one at https://console.neon.tech/settings/api-keys
  - `NEON_PROJECT_ID` — found under Project Settings → General in the Neon console

## Setup

```sh
cp .env.development.example .env.development
cp .env.production.example .env.production
```

Then fill in the real values:

- `.env.development` → set `NEON_API_KEY` and `NEON_PROJECT_ID`
- `.env.production` → set `DATABASE_URL` to your Neon Cloud connection string and `ARCJET_KEY`

## Development (Neon Local)

Neon Local is a Docker proxy that creates an **ephemeral branch** of your Neon database when the container starts, and deletes it when the container stops. Each `up` gives you a fresh copy of your database.

```sh
npm run dev:docker
```

This script (`scripts/dev.sh`, run on the host):

1. Verifies `.env.development` exists and Docker is running
2. Starts `neon-local` — the Neon proxy (exposed on host port `5432`)
3. Applies migrations against the local proxy (`postgres://neon:npg@localhost:5432/neondb`), retrying until the ephemeral branch is ready
4. Starts `app` — the API on http://localhost:3000, running `node --watch` for hot reload

The app connects to `postgres://neon:npg@neon-local:5432/neondb` (service name `neon-local` inside the Compose network).

To stop (deletes the ephemeral branch):

```sh
docker compose -f docker-compose.dev.yml down
```

### Useful commands

```sh
# Interactive DB shell against the local proxy
docker compose -f docker-compose.dev.yml exec neon-local psql postgres://neon:npg@localhost:5432/neondb

# Run Drizzle Studio against the local proxy
DATABASE_URL=postgres://neon:npg@localhost:5432/neondb npm run db:studio
```

### Branching from a specific branch

By default the ephemeral branch is created from your project's default branch. To branch from a specific branch instead, add to `.env.development`:

```sh
PARENT_BRANCH_ID=<your-parent-branch-id>
```

## Production (Neon Cloud)

No local proxy is used — the API connects directly to your Neon Cloud branch.

```sh
docker compose -f docker-compose.prod.yml up -d --build
```

The app reads `DATABASE_URL` from `.env.production` (a `*.neon.tech` connection string), so the serverless driver uses its default secure HTTPS endpoint. The prod compose command runs `npm run db:migrate` before `npm start`. Inject the same variables via your orchestrator's secret manager in real deployments rather than baking them into the image — they are never hardcoded.

## Environment variables

| Variable            | Dev value                                          | Prod value                          | Required by      |
| ------------------- | -------------------------------------------------- | ----------------------------------- | ---------------- |
| `DATABASE_URL`      | `postgres://neon:npg@neon-local:5432/neondb`       | `postgresql://...@<host>.neon.tech/...?sslmode=require` | app, migrations |
| `NEON_API_KEY`      | your Neon API key                                  | –                                   | Neon Local       |
| `NEON_PROJECT_ID`   | your Neon project ID                               | –                                   | Neon Local       |
| `PARENT_BRANCH_ID`  | optional branch ID                                 | –                                   | Neon Local       |
| `ARCJET_KEY`        | your Arcjet key                                    | your Arcjet key                     | app              |
| `PORT`              | `3000`                                             | `3000`                              | app              |
| `LOG_LEVEL`         | `info`                                             | `info`                              | app              |
| `NODE_ENV`          | `development`                                      | `production`                        | app              |

`NODE_ENV` also controls behavior: the app logs to the console in development, and only to files (`/logs`) in production.
