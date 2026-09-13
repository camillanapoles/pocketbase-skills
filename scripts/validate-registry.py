#!/usr/bin/env python3
"""Gate — Registry: integridade do cluster pocketbase-skills (fail-closed).

Valida, sem rede e sem estado externo:
  1. index.json: schema, chaves obrigatórias, compat declarada
  2. Cada skill: path/entrypoint existem; metadata.json padronizada
  3. metadata.json  ==  index.json (nome, versão, dependências, capabilities)
  4. Frontmatter `version:` do SKILL.md == metadata.version (se presente)
  5. Grafo de dependências: acíclico (Kahn), arestas resolvem
  6. Symlinks declarados: existem, resolvem e ficam dentro do repo
  7. GLOBAL_RULES.md e .shared/{common_rules.md,logger.sh} existem
  8. scripts/bootstrap-project.sh --check exit 0

Saída: lista de erros + exit 1 se qualquer regra falhar.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

REQUIRED_TOP = ("registry_version", "cluster", "description", "compatibility",
                "global_rules", "skills")
REQUIRED_COMPAT = ("pocketbase", "js_sdk", "verified_at")
REQUIRED_SKILL = ("name", "path", "entrypoint", "version", "summary",
                  "dependencies", "capabilities")
REQUIRED_META = ("skill_name", "version", "entrypoint", "summary",
                 "dependencies", "capabilities")

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)
    print(f"[ERRO] {msg}")


def ok(msg: str) -> None:
    print(f"[ OK ] {msg}")


def rel(path: str) -> str:
    return os.path.relpath(path, ROOT)


def load_index() -> dict:
    path = os.path.join(ROOT, "index.json")
    if not os.path.isfile(path):
        err("index.json ausente na raiz do cluster")
        return {}
    try:
        return json.load(open(path, encoding="utf-8"))
    except json.JSONDecodeError as e:
        err(f"index.json não parseia: {e}")
        return {}


def check_top(index: dict) -> None:
    for key in REQUIRED_TOP:
        if key not in index:
            err(f"index.json sem chave obrigatória: {key}")
    compat = index.get("compatibility", {})
    for key in REQUIRED_COMPAT:
        if key not in compat:
            err(f"index.compatibility sem chave obrigatória: {key}")
    if not isinstance(index.get("skills"), list) or not index["skills"]:
        err("index.skills deve ser lista não-vazia")


def check_skill_dirs(index: dict) -> dict[str, dict]:
    by_name: dict[str, dict] = {}
    for skill in index.get("skills", []):
        name = skill.get("name", "?")
        for key in REQUIRED_SKILL:
            if key not in skill:
                err(f"skill '{name}' sem campo obrigatório: {key}")
        if name in by_name:
            err(f"skill duplicada no index: {name}")
        by_name[name] = skill

        path = skill.get("path", "")
        dirpath = os.path.normpath(os.path.join(ROOT, path))
        if not path.startswith("./"):
            err(f"skill '{name}': path deve começar com ./ (got '{path}')")
        if not os.path.isdir(dirpath):
            err(f"skill '{name}': diretório inexistente: {path}")
            continue
        entry = os.path.normpath(os.path.join(dirpath, skill.get("entrypoint", "")))
        if not os.path.isfile(entry):
            err(f"skill '{name}': entrypoint inexistente: {path}/{skill.get('entrypoint')}")
    return by_name


def check_metadata(index: dict, by_name: dict[str, dict]) -> None:
    for skill in index.get("skills", []):
        name = skill.get("name", "?")
        dirpath = os.path.normpath(os.path.join(ROOT, skill.get("path", "")))
        meta_path = os.path.join(dirpath, "metadata.json")
        if not os.path.isfile(meta_path):
            err(f"skill '{name}': metadata.json ausente em {skill.get('path')}")
            continue
        try:
            meta = json.load(open(meta_path, encoding="utf-8"))
        except json.JSONDecodeError as e:
            err(f"skill '{name}': metadata.json não parseia: {e}")
            continue
        for key in REQUIRED_META:
            if key not in meta:
                err(f"skill '{name}': metadata sem campo obrigatório: {key}")
        if meta.get("skill_name") != name:
            err(f"skill '{name}': metadata.skill_name='{meta.get('skill_name')}' difere do index")
        if str(meta.get("version")) != str(skill.get("version")):
            err(f"skill '{name}': metadata.version={meta.get('version')} != index.version={skill.get('version')}")
        if set(meta.get("dependencies", [])) != set(skill.get("dependencies", [])):
            err(f"skill '{name}': dependencies divergem entre metadata e index")
        if set(meta.get("capabilities", [])) != set(skill.get("capabilities", [])):
            err(f"skill '{name}': capabilities divergem entre metadata e index")
        if not skill.get("capabilities"):
            err(f"skill '{name}': capabilities vazio")

        # frontmatter `version:` do SKILL.md, se declarado, deve casar
        skill_md = os.path.join(dirpath, "SKILL.md")
        if os.path.isfile(skill_md):
            head = "\n".join(open(skill_md, encoding="utf-8").read().splitlines()[:20])
            m = re.search(r'^version:\s*"?(\d+\.\d+\.\d+)"?', head, re.M)
            if m and m.group(1) != str(meta.get("version")):
                err(f"skill '{name}': frontmatter version {m.group(1)} != metadata {meta.get('version')}")


def check_dag(by_name: dict[str, dict]) -> None:
    names = set(by_name)
    indeg = {n: 0 for n in names}
    adj: dict[str, list[str]] = {n: [] for n in names}
    for name, skill in by_name.items():
        for dep in skill.get("dependencies", []):
            if dep not in names:
                err(f"skill '{name}' depende de '{dep}' que não está no cluster")
                continue
            adj[dep].append(name)
            indeg[name] += 1
    queue = [n for n, d in indeg.items() if d == 0]
    seen = 0
    while queue:
        node = queue.pop()
        seen += 1
        for nxt in adj[node]:
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                queue.append(nxt)
    if seen != len(names):
        cyc = sorted(n for n, d in indeg.items() if d > 0)
        err(f"ciclo no grafo de dependências envolvendo: {', '.join(cyc)}")
    else:
        ok(f"DAG de dependências acíclico ({len(names)} skills)")


def check_symlinks(index: dict) -> None:
    declared = 0
    for skill in index.get("skills", []):
        name = skill.get("name", "?")
        for link in skill.get("symlinks", []):
            link_path = link.get("path", "")
            target = link.get("target", "")
            if not link_path or not target:
                err(f"skill '{name}': symlink declarado sem path/target")
                continue
            declared += 1
            full = os.path.join(ROOT, link_path)
            if not os.path.islink(full):
                err(f"symlink declarado mas não existe no disco: {link_path}")
                continue
            resolved = os.path.realpath(full)
            expected = os.path.realpath(os.path.join(ROOT, target))
            if resolved != expected:
                err(f"symlink {link_path} resolve para {rel(resolved)}, esperado {target}")
                continue
            if not resolved.startswith(os.path.realpath(ROOT) + os.sep):
                err(f"symlink {link_path} escapa do repo")
                continue
            if not os.path.exists(resolved):
                err(f"symlink {link_path} → alvo inexistente: {target}")
    # symlinks no disco que não estão declarados
    on_disk = 0
    for dirpath, _dirnames, filenames in os.walk(ROOT):
        if os.path.sep + ".git" in dirpath:
            continue
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            if os.path.islink(full):
                on_disk += 1
                if not os.path.exists(full):
                    err(f"symlink quebrado (alvo inexistente): {rel(full)}")
    if declared != on_disk:
        err(f"{on_disk} symlink(s) no disco mas {declared} declarado(s) no index")
    elif declared:
        ok(f"symlinks: {declared} declarado(s) e íntegro(s)")


def check_shared_and_rules(index: dict) -> None:
    for path in ("GLOBAL_RULES.md",
                 os.path.join(".shared", "common_rules.md"),
                 os.path.join(".shared", "logger.sh"),
                 os.path.join("INDEX.md")):
        if not os.path.isfile(os.path.join(ROOT, path)):
            err(f"arquivo obrigatório ausente: {path}")


def check_bootstrap() -> None:
    script = os.path.join(ROOT, "scripts", "bootstrap-project.sh")
    if not os.path.isfile(script):
        err("scripts/bootstrap-project.sh ausente")
        return
    proc = subprocess.run(["bash", script, "--check"], cwd=ROOT,
                          capture_output=True, text=True)
    if proc.returncode != 0:
        err(f"bootstrap-project.sh --check falhou (exit {proc.returncode}):\n{proc.stdout}{proc.stderr}")


def main() -> int:
    index = load_index()
    if not index:
        print(f"\n{len(errors)} erro(s)")
        return 1
    check_top(index)
    by_name = check_skill_dirs(index)
    check_metadata(index, by_name)
    check_dag(by_name)
    check_symlinks(index)
    check_shared_and_rules(index)
    check_bootstrap()
    if errors:
        print(f"\n[ERRO] Gate - Registry: {len(errors)} falha(s)")
        return 1
    print("\n[ OK ] Gate - Registry: cluster íntegro")
    return 0


if __name__ == "__main__":
    sys.exit(main())
