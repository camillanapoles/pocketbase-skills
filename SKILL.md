---
name: pocketbase
description: >-
  Integrative PocketBase skill cluster — the single entry that routes any
  PocketBase work to the right sub-skill: pocketbase-core (backend operation
  via REST/Go: collections, records, superuser auth, backups, migrations),
  pb-react-spa (React SPA with Vite + TanStack Router/Query + shadcn), and
  pocketbase-best-practices (64 prioritized rules for schema, API rules, auth,
  queries, realtime, files, deployment, Go/JSVM). Use for anything PocketBase:
  setup, schema design, auth, frontend integration, or production hardening.
  Validated against PocketBase v0.40.4 / JS SDK v0.28.1.
license: MIT
compatibility: PocketBase v0.23+ (cluster validated against v0.40.4); JS SDK v0.28.x; Python 3 stdlib for scripts.
metadata:
  version: "1.1.0"
  cluster: pocketbase-skills
  registry: index.json
allowed-tools: Read Write Edit Bash Grep Glob
---

# PocketBase — Skill Cluster (entrada integrativa)

Esta é a porta de entrada do cluster `pocketbase-skills`. Ela **norteia e
despacha** — não duplica conteúdo. Toda instrução detalhada vive na sub-skill
correspondente; o contrato entre elas vive no registry.

## Routing — para onde ir por intenção

| Intenção | Sub-skill | Entry |
|---|---|---|
| Setup do servidor, superuser, collections, records, backups, health, migrações, e2e, Go package mode | `pocketbase-core` | [`pocketbase-core/SKILL.md`](pocketbase-core/SKILL.md) |
| SPA React: scaffold, hooks TanStack Query, auth provider, typegen, deploy | `pb-react-spa` | [`pb-react-spa/SKILL.md`](pb-react-spa/SKILL.md) |
| "Isso está seguro/escalável/bem modelado?" — schema, API rules, auth, queries, realtime, arquivos, deploy, Go/JSVM | `pocketbase-best-practices` | [`pocketbase-best-practices/SKILL.md`](pocketbase-best-practices/SKILL.md) |
| Projeto completo do zero (backend + SPA) | orquestrador | `bash scripts/bootstrap-project.sh <dir> [--frontend]` |

Tarefa composta = roteie em sequência (ex.: modelar schema → `pocketbase-core`
cria as collections → `pb-react-spa` gera os hooks), mantendo os nomes de
coleções consistentes entre os passos.

## Context loader (hierarquia obrigatória)

1. **N1 — registry:** [`INDEX.md`](INDEX.md) + [`index.json`](index.json) são
   o mapa do cluster (skills, capabilities, DAG de dependências, symlinks).
2. **N2 — descoberta:** escolha a sub-skill pelas `capabilities` do
   `metadata.json` dela.
3. **N3 — execução:** obedeça o `SKILL.md` da sub-skill escolhida **e**
   [`GLOBAL_RULES.md`](GLOBAL_RULES.md) (10 regras que valem para todas) +
   [`.shared/common_rules.md`](.shared/common_rules.md) (contrato de env
   vars: `PB_URL`, `PB_SUPERUSER_EMAIL/PASSWORD`, `PB_ENCRYPTION_KEY`).

## Regras de ouro (resumo; detalhe em GLOBAL_RULES.md)

- Registry é a fonte da verdade; API pós-v0.23 somente (`_superusers`, nunca
  `_admins`); segredos sempre em env vars; frontend em TypeScript.
- Compatibilidade é gate: [`index.json`](index.json) → `compatibility` declara
  as versões validadas; o CI do repo compara com as releases latest upstream.
- Cross-referência entre sub-skills é por symlinks declarados no registry —
  nunca copie conteúdo entre elas.

## Estado e continuidade

- Repo: `camillanapoles/pocketbase-skills` (main protegido; PRs com 3 gates).
- WAL da operação: [`HISTORY.md`](HISTORY.md) — a sessão seguinte começa dali.
- Mudanças no cluster seguem o loop GitOps: branch → CI verde → PR → merge.
