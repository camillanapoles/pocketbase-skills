# pocketbase-skills

Agent Skills cluster for building apps with [PocketBase](https://pocketbase.io/) (v0.23+, validated against **v0.40.4**) + React.

Compatible with the [Agent Skills](https://github.com/vercel-labs/skills) specification.

> **Agents:** start at [`INDEX.md`](INDEX.md) — the registry hub (skills, capabilities, dependency graph, context-loader contract).
> **Canonical map:** [`index.json`](index.json) · **Global rules:** [`GLOBAL_RULES.md`](GLOBAL_RULES.md) · **WAL:** [`HISTORY.md`](HISTORY.md)

## Skills

| Skill | Description |
|-------|-------------|
| [`pocketbase-core`](pocketbase-core/SKILL.md) | Collection CRUD, record CRUD, superuser/user authentication, backup & restore, migration file generation, and design guidance for API rules, relations, and security patterns |
| [`pb-react-spa`](pb-react-spa/SKILL.md) | React SPA frontend setup for PocketBase — Vite + TanStack Router + TanStack Query + Tailwind/Shadcn UI + Biome |
| [`pocketbase-best-practices`](pocketbase-best-practices/SKILL.md) | 64 prioritized rules: schema design, API rules, auth, queries, realtime, files, deployment, Go/JSVM extending |

The root [`SKILL.md`](SKILL.md) is the **integrative entry** — a single `pocketbase` skill that routes to the three sub-skills by intent (what omp/pi expose).

## Scaffolding a full project (backend + optional SPA)

```bash
bash scripts/bootstrap-project.sh myapp --frontend
```

## CI/CD (GitOps, deterministic gates)

- `Sintaxe (JSON/YAML/Shell/Python)` · `Gate - Registry` (index ↔ metadata ↔ DAG ↔ symlinks) · `Gate - Compat` (cluster versions vs upstream latest, fail-closed)
- main is protected: changes land via PR with all required checks green; tags `v*` cut verified releases.

## Prerequisites

- Python 3 (standard library only, no external packages)
- A running PocketBase instance (v0.23+) — [Download from GitHub Releases](https://github.com/pocketbase/pocketbase/releases/latest)
- Environment variables or `.env` file:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PB_URL` | No | `http://127.0.0.1:8090` | PocketBase base URL |
| `PB_SUPERUSER_EMAIL` | Yes* | - | Superuser email address |
| `PB_SUPERUSER_PASSWORD` | Yes* | - | Superuser password |

\*Required for superuser operations.

## License

[MIT](LICENSE.txt)
