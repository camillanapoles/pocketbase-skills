#!/usr/bin/env bash
# ============================================================================
# bootstrap-project.sh — orquestrador do cluster pocketbase-skills.
# Coordena as skills para scaffoldear um projeto real:
#   backend  -> skill `pocketbase` (pb_migrations/ + .env + .gitignore)
#   frontend -> skill `pb-react-spa` (create-tsrouter-app + SDK + shadcn)
# Uso:
#   bootstrap-project.sh --check               # valida registry + assets (CI)
#   bootstrap-project.sh <dir> [--frontend]    # scaffold real
# ============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../.shared/logger.sh
source "$ROOT/.shared/logger.sh"

cmd="${1:-}"
if [ -z "$cmd" ]; then
  echo "uso: $0 --check | $0 <dir-alvo> [--frontend]" >&2
  exit 2
fi

if [ "$cmd" = "--check" ]; then
  # Verificações PRÓPRIAS do orquestrador (sem chamar validate-registry.py —
  # o CI os executa como steps independentes; chamada cruzada = recursão).
  for asset in pocketbase/assets/migration-template.js \
               pocketbase/assets/migration-template.go; do
    [ -f "$ROOT/$asset" ] || { log_err "asset ausente: $asset"; exit 1; }
  done
  [ -f "$ROOT/.shared/logger.sh" ] || { log_err ".shared/logger.sh ausente"; exit 1; }
  jq -e '.skills | length >= 1' "$ROOT/index.json" >/dev/null \
    || { log_err "index.json ausente/inválido/vazio"; exit 1; }
  command -v npx >/dev/null 2>&1 || log_warn "npx ausente: --frontend indisponível neste host"
  log_ok "bootstrap --check: assets + index + logger íntegros"
  exit 0
fi

TARGET="$(realpath -m "$cmd")"
shift || true
FRONTEND=0
[ "${1:-}" = "--frontend" ] && FRONTEND=1
if [ -e "$TARGET" ]; then
  log_err "$TARGET já existe — recuse sobrescrever"
  exit 1
fi

log_info "Scaffolding backend (skill: pocketbase) em $TARGET"
mkdir -p "$TARGET/pb_migrations"
TS="$(date +%s)"
cp "$ROOT/pocketbase/assets/migration-template.js" "$TARGET/pb_migrations/${TS}_init.js"

cat > "$TARGET/.env.example" <<'EOF'
PB_URL=http://127.0.0.1:8090
PB_SUPERUSER_EMAIL=admin@example.com
PB_SUPERUSER_PASSWORD=change-me
# Produção: exatamente 32 chars — gere com: openssl rand -hex 16
# PB_ENCRYPTION_KEY=
EOF
cp "$TARGET/.env.example" "$TARGET/.env"

cat > "$TARGET/.gitignore" <<'EOF'
.env
pb_data/
pb_migrations/*.js.bak
node_modules/
dist/
EOF

cat > "$TARGET/README.md" <<EOF
# Projeto PocketBase (scaffold do cluster pocketbase-skills)

- Backend: skill \`pocketbase\` — $ROOT/pocketbase/SKILL.md
- Regras do cluster: $ROOT/GLOBAL_RULES.md
- Registry / mapa das skills: $ROOT/INDEX.md
- Práticas e limites de versão: $ROOT/index.json (compatibility)
EOF
log_ok "backend pronto: pb_migrations/ + .env + .gitignore + README"

if [ "$FRONTEND" = 1 ]; then
  log_info "Scaffolding SPA (skill: pb-react-spa) — create-tsrouter-app"
  command -v npx >/dev/null 2>&1 || { log_err "npx necessário para --frontend"; exit 1; }
  cd "$TARGET"
  npx create-tsrouter-app@latest frontend \
    --toolchain biome \
    --package-manager npm \
    --no-git
  cd frontend
  npm install pocketbase
  npx shadcn@latest init -d
  log_ok "frontend pronto em frontend/ — hooks e auth: $ROOT/pb-react-spa/SKILL.md"
fi

log_ok "bootstrap concluído: $TARGET"
