# GLOBAL_RULES — regras que valem para TODAS as skills do cluster

Estas regras se aplicam a qualquer agente operando em qualquer skill deste
cluster. Conflito entre regra local (skill) e global? **Global vence**, e o
conflito deve ser reportado como débito (HISTORY.md).

## Identidade e versões

1. **Registry é a fonte da verdade.** O que existe no cluster é o que está em
   `index.json`. Skill não registrada não existe; symlink não declarado é bug.
2. **Compatibilidade é gate, não intenção.** `index.json → compatibility`
   declara as versões validadas (PocketBase core e JS SDK). O CI compara com
   as releases latest upstream — upstream avançou, o gate fica vermelho até o
   cluster ser atualizado e re-validado num branch.
3. **API pós-v0.23 somente.** Nada de `_admins`, `/api/admins/*` ou
   `findAdminByEmail` — superuser é record em `_superusers`. Endpoints e
   exemplos novos seguem a superfície validada em `compatibility`.

## Padrões técnicos transversais

4. **Frontend em TypeScript.** A skill `pb-react-spa` usa Vite + TanStack
   Router/Query + Biome; tipos gerados (typegen) em vez de `any`.
5. **Padrão PocketBase de coleções.** Toda decisão de schema/API rule passa
   pelas regras da skill `pocketbase-best-practices` (comece locked, abra
   seletivamente; relations via `collectionId`; índices para campos filtrados).
6. **Segredos nunca hardcoded.** `PB_URL`, `PB_SUPERUSER_EMAIL`,
   `PB_SUPERUSER_PASSWORD`, `PB_ENCRYPTION_KEY` (32 chars exatos) vêm de env
   vars/`.env` (gitignored). Scripts e exemplos leem do ambiente.
7. **Não duplique conteúdo entre skills.** Referência compartilhada = symlink
   declarado no `index.json` (ver INDEX.md). Copy-paste entre skills é débito.

## Disciplina operacional (GitOps)

8. **Nada de push direto em main.** Todo incremento: spec com critérios
   verificáveis → branch `{feat|fix|refactor|chore|docs}/slug` → CI verde →
   PR → merge automático (checks required). Exceções operacionais ficam
   registradas em HISTORY.md.
9. **Fail-closed.** Validators e gates falham fechados: API inacessível,
   arquivo ausente ou metadata divergente = vermelho, não warning.
10. **WAL obrigatório.** Toda sessão que muda o cluster registra o que fez em
    `HISTORY.md` (a próxima sessão começa dali, não de memória).

## Context loader (níveis)

- **N1 raiz:** leia `INDEX.md` + `index.json` antes de qualquer tarefa.
- **N2 descoberta:** selecione a skill pelas `capabilities` do `metadata.json`.
- **N3 execução:** obedeça `SKILL.md` + `rules/` da skill + `GLOBAL_RULES.md`
  + `.shared/common_rules.md`.
