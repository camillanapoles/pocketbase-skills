# INDEX — PocketBase Skill Cluster (Registry & Orchestration)

> **Você é um agente e acabou de "entrar" neste diretório? Comece aqui.**
> O mapa canônico é [`index.json`](index.json) (machine-readable).
> Este arquivo é a versão human/LLM-readable do mesmo mapa — divergência
> entre os dois é bug (o gate `Gate - Registry` do CI pega).

## Descrição

Ecossistema para desenvolvimento rápido de apps com **PocketBase + React**.
Compatível com a spec [Agent Skills](https://github.com/vercel-labs/skills).

## Compatibilidade (fonte da verdade: `index.json` → `compatibility`)

| Componente | Versão validada | Política |
|---|---|---|
| PocketBase core | **0.40.4** (latest: 2026-09-12) | CI (`Gate - Compat`) compara com a release latest upstream; minor divergente ⇒ gate vermelho |
| JS SDK | **0.28.1** (latest: 2026-09-05) | idem |
| Mínimos por skill | ver `metadata.json` de cada skill (`compatibility`) | descritivo |

## Skills disponíveis

| Skill | Versão | Faz o quê | Depende de |
|---|---|---|---|
| [`pocketbase`](pocketbase/SKILL.md) | 1.0.0 | Setup/servidor + scripts REST: superuser, collections, records, backups, health, migrações, e2e | — |
| [`pb-react-spa`](pb-react-spa/SKILL.md) | 1.0.0 | SPA React (Vite + TanStack Router/Query + shadcn + Biome), hooks, auth provider, typegen, deploy | `pocketbase` |
| [`pocketbase-best-practices`](pocketbase-best-practices/SKILL.md) | 1.4.0 | 64 regras priorizadas: schema, API rules, auth, queries, realtime, arquivos, deploy, Go/JSVM | `pocketbase` |

## Grafo de dependência

```mermaid
graph LR
    pb-react-spa --> pocketbase
    pocketbase-best-practices --> pocketbase
    pocketbase --> nada["(skill raiz)"]
```

Acíclico por construção — `Gate - Registry` valida (Kahn) a cada push.

## Context Loader (contrato hierárquico do system prompt)

1. **Nível 1 (raiz)** — "Você está no cluster de skills PocketBase. Leia `INDEX.md`/`index.json` para entender a arquitetura."
2. **Nível 2 (descoberta)** — "Antes de iniciar a tarefa, escolha a skill cujo `metadata.json` declara as `capabilities` necessárias."
3. **Nível 3 (execução)** — "Siga estritamente o `SKILL.md` e as `rules/`/`references/` da skill escolhida, mais `GLOBAL_RULES.md`."

## Workflow integrado do agente

1. **Analysis** — leia `index.json`; identifique capabilities exigidas pela tarefa.
2. **Route** — ex.: "criar coleção" → skill `pocketbase`; "gerar hook React" → `pb-react-spa`; "isso é seguro/escalável?" → `pocketbase-best-practices`.
3. **Cross-Reference** — skills podem ler `references/` umas das outras **via symlinks declarados** (abaixo). Nunca copie conteúdo entre skills — linke.
4. **Execute** — respeite `GLOBAL_RULES.md` + `.shared/common_rules.md`.
5. **Projeto novo do zero** — `bash scripts/bootstrap-project.sh <dir> [--frontend]`.

## Symlinks declarados (fonte única, zero duplicação)

| Link | Aponta para | Por quê |
|---|---|---|
| `pb-react-spa/references/pocketbase-api.md` | `pocketbase/references/api-rules-guide.md` | Contrato de API rules compartilhado |
| `pb-react-spa/references/best-practices.md` | `pocketbase-best-practices/SKILL.md` | Índice de regras aplicáveis ao frontend |

Integridade verificada por `Gate - Registry`: symlink no disco deve estar declarado no `index.json` e resolver dentro do repo.

## Anatomia padronizada de cada skill

```
<skill>/
├── metadata.json   # machine-readable: nome, versão, deps, capabilities (schema do cluster)
├── SKILL.md        # entrypoint conceitual (human/LLM-readable)
├── scripts/        # ações executáveis (quando houver)
├── references/     # docs de apoio sob demanda
└── rules/          # regras atômicas (quando houver)
```

## Orquestração e gates (CI/CD GitOps)

- Loop: spec → branch `{feat|fix|refactor|chore|docs}/slug` → push → CI gateia → PR quando M==N → auto-merge → main protegido → tag `v*` → release.
- Checks required: `Sintaxe (JSON/YAML/Shell/Python)` · `Gate - Registry` · `Gate - Compat`.
- Validadores rodam localmente também: `python3 scripts/validate-registry.py` · `bash scripts/validate-compat.sh` · `bash scripts/bootstrap-project.sh --check`.

## Como adicionar uma skill nova

1. Crie `<slug>/` com a anatomia acima (`metadata.json` + `SKILL.md`).
2. Registre em `index.json` (skills + dependências + capabilities).
3. Rode `python3 scripts/validate-registry.py` — verde? commit no branch, o CI re-gateia.
4. Atualize este INDEX.md (tabela + grafo, se o grafo mudar).
