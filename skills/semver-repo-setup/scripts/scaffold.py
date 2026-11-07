#!/usr/bin/env python3
"""Génère l'outillage d'un dépôt (workflow « lots de version semver »).

Copie les couches d'assets dans l'ordre common → <profil> → <profil>-docker (si --docker),
une couche plus spécifique remplaçant un fichier de même chemin. Dans chaque fichier :

- remplace les variables ``__NOM__`` (voir ``variables()``) ;
- traite les blocs ``# >>> tag`` … ``# <<< tag`` (ou ``<!-- >>> tag -->``) : conservés si
  le tag est actif (``docker`` avec --docker, ``no-docker`` sinon), supprimés sinon ;
  les lignes de marqueur sont toujours retirées ;
- renomme ``__PACKAGE__`` dans les chemins.

N'écrase jamais un fichier existant sans --force. Bibliothèque standard uniquement.

Exemple :
    scaffold.py --dest . --owner WillIsback --repo P8-mon-projet --title "Mon projet" \\
        --description "POC …" --author "William Derue" --profile python-uv --docker
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"
PROFILES = sorted(p.name for p in ASSETS.iterdir() if p.is_dir() and p.name != "common"
                  and not p.name.endswith("-docker"))
MARKER = re.compile(r"^\s*(?:#|<!--)\s*(>>>|<<<)\s*([\w-]+)\s*(?:-->)?\s*$")
TEXT_SUFFIXES = {"", ".py", ".toml", ".yml", ".yaml", ".md", ".json", ".txt", ".cfg", ".ini"}


def render_blocks(text: str, active: set[str]) -> str:
    out: list[str] = []
    stack: list[tuple[str, bool]] = []
    for line in text.splitlines(keepends=True):
        match = MARKER.match(line)
        if match:
            kind, tag = match.groups()
            if kind == ">>>":
                stack.append((tag, tag in active))
            else:
                if not stack or stack[-1][0] != tag:
                    raise ValueError(f"marqueur « <<< {tag} » sans ouverture correspondante")
                stack.pop()
            continue
        if all(keep for _, keep in stack):
            out.append(line)
    if stack:
        raise ValueError(f"bloc « >>> {stack[-1][0]} » non fermé")
    return "".join(out)


def substitute(text: str, values: dict[str, str]) -> str:
    # Plusieurs passes : une valeur peut contenir une autre variable (ex. DEV_COMMANDS).
    for _ in range(3):
        for key, value in values.items():
            text = text.replace(f"__{key}__", value)
    return text


def variables(args: argparse.Namespace, profile: dict[str, object]) -> dict[str, str]:
    docker = "_DOCKER" if args.docker else ""
    values = {
        "OWNER": args.owner,
        "REPO": args.repo,
        "TITLE": args.title,
        "DESCRIPTION": args.description,
        "AUTHOR": args.author,
        "YEAR": str(dt.date.today().year),
        "PACKAGE": args.package,
        "DIST_NAME": args.package.replace("_", "-"),
        "PYTHON_VERSION": args.python,
        "PYTHON_NODOT": args.python.replace(".", ""),
        "PROJECT_NUMBER": args.project_number,
    }
    for key in ("LOCAL_CHECKS", "DEV_COMMANDS", "GATES_ROWS"):
        value = profile.get(f"{key}{docker}", profile.get(key, ""))
        values[key] = str(value)
    return values


def layers(profile: str, docker: bool) -> list[Path]:
    result = [ASSETS / "common", ASSETS / profile]
    if docker and (ASSETS / f"{profile}-docker").is_dir():
        result.append(ASSETS / f"{profile}-docker")
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dest", type=Path, default=Path("."))
    parser.add_argument("--owner", required=True)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--description", required=True)
    parser.add_argument("--author", required=True)
    parser.add_argument("--profile", choices=PROFILES, default="python-uv")
    parser.add_argument("--package", help="nom du package importable (défaut : dérivé du dépôt)")
    parser.add_argument("--python", default="3.12")
    parser.add_argument("--docker", action="store_true", help="image Docker publiée en release")
    parser.add_argument("--project-number", default="__PROJECT_NUMBER__",
                        help="numéro du Project GitHub (sinon laissé à remplacer)")
    parser.add_argument("--force", action="store_true", help="écraser les fichiers existants")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    if not args.package:
        args.package = re.sub(r"[^a-z0-9]+", "_", args.repo.lower()).strip("_")
        if args.package[0].isdigit():
            args.package = f"p_{args.package}"
    if not re.fullmatch(r"[a-z_][a-z0-9_]*", args.package):
        parser.error(f"--package invalide : {args.package!r}")

    profile_file = ASSETS / args.profile / "profile.json"
    profile = json.loads(profile_file.read_text(encoding="utf-8")) if profile_file.is_file() else {}
    values = variables(args, profile)
    active = {args.profile, "docker" if args.docker else "no-docker"}

    files: dict[Path, Path] = {}
    for layer in layers(args.profile, args.docker):
        for src in sorted(p for p in layer.rglob("*") if p.is_file()):
            rel = src.relative_to(layer)
            if rel.name == "profile.json" and rel.parent == Path("."):
                continue
            files[Path(str(rel).replace("__PACKAGE__", args.package))] = src

    written = skipped = 0
    for rel, src in sorted(files.items()):
        target = args.dest / rel
        if target.exists() and not args.force:
            print(f"= existe déjà, conservé : {rel}")
            skipped += 1
            continue
        if src.suffix in TEXT_SUFFIXES or src.name in {"Dockerfile", ".aikido"}:
            content = substitute(render_blocks(src.read_text(encoding="utf-8"), active), values)
            leftover = sorted(set(re.findall(r"__[A-Z][A-Z_]+__", content)) - {"__PROJECT_NUMBER__"})
            if leftover:
                raise SystemExit(f"{rel} : variables non remplacées {leftover}")
            data = content.encode("utf-8")
        else:
            data = src.read_bytes()
        print(f"+ {rel}")
        if not args.dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        written += 1

    print(f"\n{written} fichier(s) écrit(s), {skipped} conservé(s). Profil {args.profile}"
          f"{' + docker' if args.docker else ''}, package {args.package}.")
    if profile.get("post_commands"):
        print("Étapes suivantes : " + " && ".join(profile["post_commands"]))  # type: ignore[arg-type]
    return 0


if __name__ == "__main__":
    sys.exit(main())
