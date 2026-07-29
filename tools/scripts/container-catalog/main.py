#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any, NoReturn, cast

ALLOWED_PLATFORMS = {"linux/amd64", "linux/arm64", "linux/arm/v7"}
NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:[._-][a-z0-9]+)*$")
DOCUMENTATION_PATH = ".github/AUTOMATION.md"


def fail(message: str) -> NoReturn:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def repository_root() -> Path:
    return Path(__file__).resolve().parents[3]


def safe_relative_path(value: object, field: str) -> PurePosixPath:
    if not isinstance(value, str) or not value:
        fail(f"{field} deve ser uma string não vazia")
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or "\\" in value:
        fail(f"{field} contém caminho inseguro: {value}")
    return path


def read_catalog(catalog_path: Path) -> list[dict[str, object]]:
    catalog: Any = None
    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"não foi possível ler {catalog_path}: {error}")

    if not isinstance(catalog, dict) or catalog.get("schemaVersion") != 1 or not isinstance(catalog.get("images"), list):
        fail("catálogo deve usar schemaVersion 1 e conter a lista images")
    return cast(list[dict[str, object]], catalog["images"])


def validate_names(image: dict[str, object], index: int, ids: set[str]) -> str:
    image_id = image.get("id")
    image_name = image.get("imageName")
    if not isinstance(image_id, str) or not NAME_PATTERN.fullmatch(image_id):
        fail(f"id inválido em images[{index}]: {image_id}")
    if not isinstance(image_name, str) or not NAME_PATTERN.fullmatch(image_name):
        fail(f"imageName inválido para {image_id}: {image_name}")
    if image_id in ids:
        fail(f"id duplicado: {image_id}")
    ids.add(image_id)
    return image_id


def validate_paths(
    image: dict[str, object], image_id: str, root: Path, coordinates: set[tuple[str, str]]
) -> str:
    context = safe_relative_path(image.get("context"), f"context de {image_id}")
    dockerfile = safe_relative_path(image.get("dockerfile"), f"dockerfile de {image_id}")
    if len(dockerfile.parts) != 1 or not dockerfile.name.startswith("Dockerfile"):
        fail(f"dockerfile inválido para {image_id}: {dockerfile}")
    coordinate = (context.as_posix(), dockerfile.as_posix())
    if coordinate in coordinates:
        fail(f"contexto e Dockerfile duplicados: {context}/{dockerfile}")
    coordinates.add(coordinate)

    context_path = (root / context).resolve()
    dockerfile_path = (context_path / dockerfile).resolve()
    if not context_path.is_relative_to(root) or not context_path.is_dir():
        fail(f"contexto inexistente ou fora do repositório para {image_id}: {context}")
    if not dockerfile_path.is_relative_to(context_path) or not dockerfile_path.is_file():
        fail(f"Dockerfile inexistente ou fora do contexto para {image_id}: {dockerfile_path}")
    return dockerfile_path.relative_to(root).as_posix()


def validate_platforms(image: dict[str, object], image_id: str) -> None:
    platforms = image.get("platforms")
    scan_platform = image.get("scanPlatform")
    if (
        not isinstance(platforms, list)
        or not platforms
        or not all(isinstance(platform, str) for platform in platforms)
        or len(platforms) != len(set(platforms))
    ):
        fail(f"platforms deve ser uma lista não vazia e sem duplicatas para {image_id}")
    platforms = cast(list[str], platforms)
    if not isinstance(scan_platform, str):
        fail(f"scanPlatform deve ser uma string para {image_id}")
    if any(platform not in ALLOWED_PLATFORMS for platform in platforms):
        fail(f"plataforma não permitida para {image_id}: {platforms}")
    if scan_platform not in platforms:
        fail(f"scanPlatform deve estar em platforms para {image_id}")


def validate_policy(image: dict[str, object], image_id: str) -> None:
    validation = image.get("validation")
    if validation not in {"build", "check"}:
        fail(f"validation deve ser build ou check para {image_id}")
    if validation == "check" and not image.get("reason"):
        fail(f"reason é obrigatório quando validation=check para {image_id}")


def validate_coverage(root: Path, catalog_dockerfiles: set[str]) -> None:
    discovered = {
        path.relative_to(root).as_posix()
        for path in root.rglob("Dockerfile*")
        if path.is_file() and ".github" not in path.relative_to(root).parts
    }
    missing = sorted(discovered - catalog_dockerfiles)
    stale = sorted(catalog_dockerfiles - discovered)
    if missing or stale:
        fail(f"cobertura divergente; ausentes={missing}; obsoletos={stale}")


def load_and_validate_catalog() -> list[dict[str, object]]:
    root = repository_root()
    images = read_catalog(root / "tools" / "container-images.json")

    ids: set[str] = set()
    coordinates: set[tuple[str, str]] = set()
    catalog_dockerfiles: set[str] = set()

    for index, image in enumerate(images):
        if not isinstance(image, dict):
            fail(f"images[{index}] deve ser um objeto")
        image_id = validate_names(image, index, ids)
        catalog_dockerfiles.add(validate_paths(image, image_id, root, coordinates))
        validate_platforms(image, image_id)
        validate_policy(image, image_id)

    validate_coverage(root, catalog_dockerfiles)
    return images


def git_changed_files(base: str, head: str) -> list[str]:
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", "--diff-filter=ACMR", f"{base}...{head}"],
            cwd=repository_root(),
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        details = (error.stderr or error.stdout or "erro desconhecido").strip()
        fail(f"não foi possível consultar o diff Git entre {base} e {head}: {details}")
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def matrix_for_changes(images: list[dict[str, object]], changed_files: list[str]) -> list[dict[str, object]]:
    selected: dict[str, dict[str, object]] = {}
    for changed_file in changed_files:
        changed = PurePosixPath(changed_file)
        candidates = [
            image
            for image in images
            if changed == PurePosixPath(str(image["context"]))
            or PurePosixPath(str(image["context"])) in changed.parents
        ]
        exact_dockerfiles = [
            image
            for image in candidates
            if changed.as_posix() == f'{image["context"]}/{image["dockerfile"]}'
        ]
        for image in exact_dockerfiles or candidates:
            selected[str(image["id"])] = image
    return [selected[key] for key in sorted(selected)]


def release_entry(
    images: list[dict[str, object]], context: str, dockerfile: str, image_name: str, platforms: str
) -> dict[str, object]:
    requested_platforms = platforms.split(",")
    matches = [
        image
        for image in images
        if image["context"] == context
        and image["dockerfile"] == dockerfile
        and image["imageName"] == image_name
    ]
    if len(matches) != 1:
        fail(
            "context, Dockerfile e nome da imagem não correspondem exatamente "
            "a uma entrada de tools/container-images.json"
        )
    allowed_platforms = cast(list[str], matches[0]["platforms"])
    if not requested_platforms or any(not platform for platform in requested_platforms):
        fail("ao menos uma plataforma deve ser informada")
    if len(requested_platforms) != len(set(requested_platforms)):
        fail(f"plataformas duplicadas para {image_name}: {platforms}")
    unavailable_platforms = [
        platform for platform in requested_platforms if platform not in allowed_platforms
    ]
    if unavailable_platforms:
        fail(
            f"plataformas não catalogadas para {image_name}: {','.join(unavailable_platforms)}; "
            f"opções={','.join(allowed_platforms)}"
        )
    selected_platforms = [
        platform for platform in allowed_platforms if platform in requested_platforms
    ]
    return {**matches[0], "platforms": selected_platforms}


def compact_json(value: object) -> str:
    return json.dumps(value, separators=(",", ":"), ensure_ascii=True)


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Valida e consulta o catálogo de imagens de container do repositório.",
        epilog=(
            "Dependências: Python 3.12+, uv 0.9.26 e Git (somente para o comando matrix).\n"
            "Exemplos:\n"
            "  uv run --project tools python tools/scripts/container-catalog/main.py validate\n"
            "  uv run --project tools python tools/scripts/container-catalog/main.py matrix --base HEAD^ --head HEAD\n"
            "Documentação: " + DOCUMENTATION_PATH
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True, title="comandos")

    subparsers.add_parser(
        "validate",
        help="valida estrutura, segurança de paths, políticas e cobertura do catálogo",
        description="Valida o catálogo contra todos os Dockerfiles do repositório.",
    )

    matrix_parser = subparsers.add_parser(
        "matrix",
        help="gera a matriz JSON das imagens alteradas entre duas revisões Git",
        description="Seleciona imagens afetadas pelo diff Git e imprime uma matriz JSON compacta.",
    )
    matrix_parser.add_argument("--base", required=True, help="revisão Git base do diff")
    matrix_parser.add_argument("--head", required=True, help="revisão Git final do diff")

    release_parser = subparsers.add_parser(
        "release",
        help="confere se os inputs e as plataformas de publicação são permitidos pelo catálogo",
        description="Valida os inputs de uma release e imprime a entrada JSON correspondente.",
    )
    release_parser.add_argument("--context", required=True, help="diretório de contexto relativo ao repositório")
    release_parser.add_argument("--dockerfile", required=True, help="nome do Dockerfile dentro do contexto")
    release_parser.add_argument("--image-name", required=True, help="nome da imagem sem o namespace do registry")
    release_parser.add_argument(
        "--platforms", required=True, help="uma ou mais plataformas catalogadas, separadas por vírgula"
    )
    return parser


def main() -> None:
    arguments = create_parser().parse_args()
    images = load_and_validate_catalog()
    if arguments.command == "validate":
        print(f"Catálogo válido: {len(images)} imagens.")
    elif arguments.command == "matrix":
        matrix = matrix_for_changes(images, git_changed_files(arguments.base, arguments.head))
        print(compact_json({"include": matrix}))
    else:
        print(
            compact_json(
                release_entry(
                    images,
                    arguments.context,
                    arguments.dockerfile,
                    arguments.image_name,
                    arguments.platforms,
                )
            )
        )


if __name__ == "__main__":
    main()