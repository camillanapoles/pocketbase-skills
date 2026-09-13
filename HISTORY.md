# HISTORY — WAL do cluster pocketbase-skills

Nova sessão: leia este arquivo de baixo pra cima (mais recente no fim por
bloco de data). Cada incremento registra o que fez, evidência e próximos
passos. É a continuidade entre sessões (nunca de memória).

## 2026-09-13 — bootstrap: remoto + Registry & Orchestration + gates

**Contexto:** cluster local `~/SKILLS/pocketbase` (3 skills) sem remoto, sem
registry, sem CI. Pedido: criar remoto GitHub + arquitetura Registry &
Orchestration + validar integração/compatibilidade com a versão mais recente.

**Feito:**
- Remoto criado: https://github.com/camillanapoles/pocketbase-skills (público
  — plano free roda Actions só em repo público; conteúdo é docs/scripts,
  scan de segredos limpo). `main` enviado (e497a5e "init").
- Compat validada contra releases latest upstream (GitHub API, 2026-09-13):
  - PocketBase core **v0.40.4** (publicada 2026-09-12) · JS SDK **v0.28.1**
    (2026-09-05).
  - `pocketbase/`: endpoints REST dos scripts são superfície pós-v0.23
    (`_superusers`, `/api/collections/*/records`, `/api/backups`,
    `/api/health`) — íntegros em v0.40.4. Sem alteração.
  - `pocketbase-best-practices/`: já curada até v0.40 (ago/2026). Sem
    alteração de conteúdo; metadata padronizada no schema do cluster.
  - `pb-react-spa/`: gap real — Docker pin `PB_VERSION=0.28.2` → **0.40.4**
    (`references/deployment.md`).
- Registry & Orchestration (branch `feat/registry-orchestration`):
  - `index.json` — manifesto canônico: 3 skills, capabilities, DAG de deps,
    symlinks declarados, bloco `compatibility` (normativo).
  - `INDEX.md` — hub human/LLM-readable: mapa, grafo, context loader N1–N3,
    workflow do agente, anatomia padrão, receita de adição de skill.
  - `GLOBAL_RULES.md` — 10 regras globais (registry = verdade, compat = gate,
    API pós-v0.23, TypeScript, best-practices obrigatórias, segredos em env,
    sem duplicação entre skills, GitOps, fail-closed, WAL).
  - `.shared/` — `common_rules.md` (contrato de env vars, convenções de
    saída, política de versões, cross-referência) + `logger.sh`.
  - `metadata.json` padronizado nas 3 skills (schema único; cross-check com
    index.json pelo validator).
  - Symlinks: `pb-react-spa/references/pocketbase-api.md` →
    `pocketbase/references/api-rules-guide.md`; `pb-react-spa/references/
    best-practices.md` → `pocketbase-best-practices/SKILL.md`.
  - Orquestrador `scripts/bootstrap-project.sh` (--check p/ CI; scaffold real
    de backend + SPA opcional) e validators `scripts/validate-registry.py`
    (integridade fail-closed) e `scripts/validate-compat.sh` (versões vs
    upstream, fail-closed).
  - CI (3 checks required): `Sintaxe (JSON/YAML/Shell/Python)` ·
    `Gate - Registry` · `Gate - Compat`. CD por tag `v*` com release
    verificado.

**Próximos passos desta sessão — CONCLUÍDOS:**
- [x] push do branch → CI verde 3/3 gates (run 34780965975, 10s, success)
- [x] PR #1 → auto-merge (c3c6464, 2026-09-13T20:31:15Z, sem humano no
  circuito) → main protegido (3 contexts required, strict, auto-merge ON) →
  tag v1.0.0 → release verificado (run CD 34781045438):
  https://github.com/camillapoles/pocketbase-skills/releases/tag/v1.0.0
  (asset: pocketbase-skills-v1.0.0.zip)


**Spec do incremento (M==N):**
1. index.json parseia; lista 3 skills; compatibility declarada
2. metadata.json padronizado ×3, consistente com index (nome/versão/deps/caps)
3. DAG acíclico; dependências existem
4. Symlinks declarados resolvem dentro do repo
5. GLOBAL_RULES + .shared existem e scripts passam bash -n
6. validate-registry / bootstrap --check / validate-compat exit 0
7. Pins PB_VERSION= casam com o minor do index (0.28.2 → 0.40.4 corrigido)
8. Workflows CI/CD YAML válidos
9. HISTORY.md (este WAL) + README aponta para INDEX.md

**Achados do pre-flight local (loop vermelho→corrige→verde, antes do push):**
- Bug pego pelo próprio gate: `bootstrap --check` chamava
  `validate-registry.py`, que chama `bootstrap --check` — recursão infinita.
  Fix: `--check` faz verificações próprias (assets + logger + index parse);
  no CI os dois são steps independentes.
- `Gate - Compat` flaggerou o próprio HISTORY.md (pin antigo citado como
  fato histórico). Exceção consciente e documentada no validator: HISTORY.md
  fora do grep de pins (narrativa de auditoria); pins vivos seguem gateados.
- Resultado local final: Registry ✓ · bootstrap --check ✓ · Compat ✓ (PB
  0.40.4 · SDK 0.28.1, conferido contra a API) · Sintaxe ✓ (4 JSON, YAML,
  bash -n, compileall).

## 2026-09-13 — orchestrator-entry: skill `pocketbase` integrativa

**Contexto:** usuário quer UMA entrada única no harness (estilo
plugin/extension) — a skill `pocketbase` norteia e despacha para os 3
diretórios, em vez de 3 skills irmãs expostas.

**Feito (branch `feat/orchestrator-entry`):**
- Sub-skill `pocketbase` renomeada para **`pocketbase-core`** (git mv;
  frontmatter, metadata 1.1.0, deps dos outros metadata, symlink target,
  bootstrap/CI paths, INDEX/README/common_rules).
- **`SKILL.md` na raiz do cluster** = skill `pocketbase` (entrada
  integrativa): routing por intenção → sub-skill, context loader N1–N3,
  regras de ouro, estado/continuidade. `index.json` ganha
  `entrypoint_skill` e registry_version 1.1.0.
- Instalação em `~/.agents/skills/` trocada: 3 symlinks → **1 symlink da
  raiz** (`pocketbase`). omp expõe a entrada integrativa; pi (descoberta
  recursiva) expõe entrada + sub-skills.

**Spec (M==N):** 1) git mv sem resíduos do nome antigo em código/paths; 2)
root SKILL.md com frontmatter válido (name/description); 3) index.json
consistente (Gate - Registry verde); 4) symlink cross-skill resolvendo p/
pocketbase-core; 5) CI/CD paths atualizados; 6) validators verdes local;
7) reinstalação única em ~/.agents/skills; 8) HISTORY + INDEX/README coerentes.

## Estado para a próxima sessão

- main = v1.1.0 (entrada integrativa `pocketbase` + sub-skills pocketbase-core
  / pb-react-spa / pocketbase-best-practices; gates + compat PB 0.40.4 / SDK
  0.28.1). Instalado em `~/.agents/skills/pocketbase` (1 symlink da raiz).
- Débitos abertos: nenhum bloqueante. Candidatos:
  - `pocketbase-best-practices` metadata `meta.upstream` aponta para o repo
    upstream de origem (greendesertsnow/pocketbase-skills) — manter sync ou
    fork-policy explícita se o cluster divergir.
  - Suggest: cobrir `pb-react-spa` com capability de realtime/hooks quando
    o conteúdo da skill ganhar exemplos de subscription.
- Próximo incremento segue R1–R9 a partir de main atualizado.

> Convenção do WAL: o bloco `## Estado para a próxima sessão` fica SEMPRE
> no fim do arquivo — o `tail` do `iniciar-sessao.sh` é o que a próxima
> sessão vê primeiro.
