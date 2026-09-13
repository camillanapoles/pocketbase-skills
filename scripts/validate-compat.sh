#!/usr/bin/env bash
# ============================================================================
# Gate — Compat: versões declaradas no cluster vs releases latest upstream.
# Fail-closed: API do GitHub inacessível ⇒ falha o gate.
# Regras:
#   R1 index.json compatibility.pocketbase/js_sdk devem casar (major.minor)
#      com a latest release upstream (pocketbase/pocketbase, pocketbase/js-sdk).
#   R2 Qualquer pin literal PB_VERSION=<ver> no repo deve casar (major.minor)
#      com compatibility.pocketbase.
#   R3 Qualquer pin literal pocketbase@<ver> (npm) deve casar (major.minor)
#      com compatibility.js_sdk.
# Uso: bash validate-compat.sh   (opcional: GITHUB_TOKEN para rate limit)
# ============================================================================
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../.shared/logger.sh
source "$ROOT/.shared/logger.sh"

AUTH=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

latest_tag() {
  curl -fsSL --max-time 30 "${AUTH[@]}" \
    "https://api.github.com/repos/$1/releases/latest" \
    | jq -r '.tag_name // empty' | sed 's/^v//'
}
minor() { printf '%s' "$1" | cut -d. -f1-2; }

log_info "Consultando releases latest upstream (GitHub API)..."
PB_LATEST="$(latest_tag pocketbase/pocketbase)" || {
  log_err "API GitHub inacessível (pocketbase/pocketbase) — fail-closed"; exit 1; }
SDK_LATEST="$(latest_tag pocketbase/js-sdk)" || {
  log_err "API GitHub inacessível (pocketbase/js-sdk) — fail-closed"; exit 1; }
[ -n "$PB_LATEST" ]  || { log_err "tag latest PB vazia"; exit 1; }
[ -n "$SDK_LATEST" ] || { log_err "tag latest SDK vazia"; exit 1; }

PB_INDEX="$(jq -r '.compatibility.pocketbase' "$ROOT/index.json")"
SDK_INDEX="$(jq -r '.compatibility.js_sdk' "$ROOT/index.json")"
log_info "upstream: PB ${PB_LATEST} · SDK ${SDK_LATEST}"
log_info "index:    PB ${PB_INDEX} · SDK ${SDK_INDEX} (verified_at $(jq -r .compatibility.verified_at "$ROOT/index.json"))"

fail=0
[ "$(minor "$PB_INDEX")" = "$(minor "$PB_LATEST")" ] || {
  log_err "index.json pocketbase ${PB_INDEX} fora do minor latest (${PB_LATEST}) — atualize o cluster"; fail=1; }
[ "$(minor "$SDK_INDEX")" = "$(minor "$SDK_LATEST")" ] || {
  log_err "index.json js_sdk ${SDK_INDEX} fora do minor latest (${SDK_LATEST}) — atualize o cluster"; fail=1; }

# R2 — pins PB_VERSION= (Dockerfiles, docs, yml)
while IFS= read -r hit; do
  file="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"; line="${rest#*:}"
  pin="$(printf '%s' "$line" | sed -n 's/.*PB_VERSION=\([0-9][0-9.]*\).*/\1/p')"
  [ -n "$pin" ] || continue
  if [ "$(minor "$pin")" != "$(minor "$PB_INDEX")" ]; then
    log_err "${file#$ROOT/}:$lineno — pin PB_VERSION=$pin fora do minor do cluster ($PB_INDEX)"
    fail=1
  fi
done < <(grep -rn 'PB_VERSION=' "$ROOT" \
          --include='*.md' --include='Dockerfile*' --include='*.yml' --include='*.yaml' \
          2>/dev/null \
          | grep -v "^$ROOT/HISTORY.md:" \
          || true)
# HISTORY.md é narrativa de auditoria (pins antigos citados como fato
# histórico, ex. "0.28.2 -> 0.40.4"); pins VIVOS estão em código e docs de
# configuração, que seguem gateados.

# R3 — pins npm pocketbase@<ver>
while IFS= read -r hit; do
  file="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"; line="${rest#*:}"
  pin="$(printf '%s' "$line" | sed -n 's/.*pocketbase@\([0-9][0-9.^~x]*\).*/\1/p')"
  [ -n "$pin" ] || continue
  base="${pin#^}"; base="${base#\~}"
  if [ "$(minor "$base")" != "$(minor "$SDK_INDEX")" ] && [ "$base" != "${SDK_INDEX}" ]; then
    log_err "${file#$ROOT/}:$lineno — pin pocketbase@$pin fora da versão do cluster ($SDK_INDEX)"
    fail=1
  fi
done < <(grep -rn 'pocketbase@[0-9]' "$ROOT" \
          --include='*.md' --include='*.json' --include='*.yml' --include='*.yaml' \
          2>/dev/null | grep -v 'create-tsrouter-app' || true)

if [ "$fail" = 0 ]; then
  log_ok "Compat: cluster em dia com PB ${PB_LATEST} e JS SDK ${SDK_LATEST}"
else
  log_err "Gate - Compat: falhou — corrija no branch e push de novo"
fi
exit "$fail"
