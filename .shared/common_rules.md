# common_rules — convenções operacionais compartilhadas

Detalhes finos que `GLOBAL_RULES.md` delega. Scripts do cluster devem seguir
isto para comporem bem uns com os outros.

## Contrato de variáveis de ambiente

| Variável | Obrigatória | Default | Uso |
|---|---|---|---|
| `PB_URL` | não | `http://127.0.0.1:8090` | Base URL da instância |
| `PB_SUPERUSER_EMAIL` | operações superuser | — | Auth em `_superusers` |
| `PB_SUPERUSER_PASSWORD` | operações superuser | — | Auth em `_superusers` |
| `PB_ENCRYPTION_KEY` | produção | — | 32 chars exatos; criptografa `_params` em repouso |

Scripts Python da skill `pocketbase-core` leem env vars **ou** `.env` no CWD —
nunca aceitam credenciais por argumento de linha de comando (vazam no shell
history / `ps`).

## Convenções de saída de scripts

- Sucesso: JSON válido em stdout, exit 0.
- Falha: mensagem em stderr, exit ≠ 0 ( scripts `pocketbase-core/scripts/*.py`
  usam `print_result(ok, status, data)` — manter o contrato).
- Logs de scripts shell usam `.shared/logger.sh` (`log_info/log_ok/log_warn/
  log_err`) — stdout para INFO/OK, stderr para WARN/ERRO.

## Política de versões

- Fonte da verdade: `index.json → compatibility` (+ `verified_at`).
- Upstream (PocketBase core / JS SDK) passou do minor declarado ⇒ atualize o
  cluster num branch: revise os pontos anotados por versão nas referências,
  ajuste pins (`PB_VERSION=`, `pocketbase@x`), bump `compatibility` +
  `verified_at`, push — `Gate - Compat` revalida.
- Cada skill declara mínimos próprios em `metadata.json → compatibility`
  (descritivo); o cluster declara o validado (normativo).

## Cross-referência entre skills

- Lê referências de outra skill **pelo symlink declarado** em `index.json`
  (ex.: `pb-react-spa/references/pocketbase-api.md`), não por cópia.
- Nomes de coleções/tabelas citados por uma skill devem ser consultados na
  skill que as define — o symlink existe exatamente para isso.
