#!/usr/bin/env bash
# ============================================================================
# logger.sh — convenção de log compartilhada do cluster pocketbase-skills.
# Source nos scripts shell:  source "$ROOT/.shared/logger.sh"
# Convenção: INFO/OK em stdout; WARN/ERRO em stderr. Exit codes ficam a cargo
# de quem chama — este arquivo nunca faz exit.
# ============================================================================
log_info() { printf '[INFO] %s\n' "$*"; }
log_ok()   { printf '[ OK ] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_err()  { printf '[ERRO] %s\n' "$*" >&2; }
