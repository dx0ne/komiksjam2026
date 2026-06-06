#!/usr/bin/env python3
"""Find Godot project files not reachable from main scene + autoloads.

Usage:
    python tools/find_unused.py
    python tools/find_unused.py --include-legacy
    python tools/find_unused.py --json
    python tools/find_unused.py --verbose
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import deque
from pathlib import Path

# Directories excluded from scanning entirely.
SKIP_DIRS = {".godot", ".git", "__pycache__", ".tasks", "design", "tools"}

# Directories treated as archived (reported separately unless --include-legacy).
ARCHIVE_DIRS = {"legacy"}

# Godot special files always considered roots even without explicit references.
ALWAYS_ROOT = {
    "project.godot",
    "icon.svg",
    "default_bus_layout.tres",
}

# Sidecar / engine files — never reported as unused.
IGNORE_SUFFIXES = {".uid", ".import"}

# Extensions treated as project resources when reporting unused files.
RESOURCE_SUFFIXES = {
    ".gd",
    ".tscn",
    ".tres",
    ".gdshader",
    ".png",
    ".jpg",
    ".jpeg",
    ".svg",
    ".webp",
    ".ogv",
    ".mp4",
    ".avi",
    ".wav",
    ".ogg",
    ".mp3",
    ".ttf",
    ".otf",
}

# Files we read to discover references.
SEARCHABLE_SUFFIXES = {
    ".gd",
    ".tscn",
    ".tres",
    ".gdshader",
    ".godot",
    ".import",
}

RES_PATH_RE = re.compile(r"res://[^\s\"'<>]+")
UID_RE = re.compile(r"uid://[a-z0-9]+")
SCENE_UID_RE = re.compile(r'uid="(uid://[a-z0-9]+)"')
CLASS_NAME_RE = re.compile(r"^class_name\s+(\w+)", re.MULTILINE)
MAIN_SCENE_RE = re.compile(r'run/main_scene="([^"]+)"')
AUTOLOAD_RE = re.compile(r'^(\w+)="\*?(res://[^"]+|uid://[^"]+)"', re.MULTILINE)
ICON_RE = re.compile(r'config/icon="(res://[^"]+)"')


def should_skip_dir(name: str, include_legacy: bool) -> bool:
    if name in SKIP_DIRS:
        return True
    if not include_legacy and name in ARCHIVE_DIRS:
        return True
    return False


def iter_files(root: Path, include_legacy: bool):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(should_skip_dir(part, include_legacy) for part in path.parts):
            continue
        yield path


def rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def normalize_res_path(raw: str, root: Path) -> str | None:
    path = raw.split("#", 1)[0].rstrip(".,;)")
    if not path.startswith("res://"):
        return None
    rel_path = path.removeprefix("res://")
    candidate = root / rel_path
    if candidate.exists():
        return rel_path
    # Try without trailing fragments Godot sometimes omits in shorthand.
    while "/" in rel_path:
        rel_path = rel_path.rsplit("/", 1)[0]
        candidate = root / rel_path
        if candidate.exists():
            return rel_path
    return None


def build_uid_index(root: Path, include_legacy: bool) -> dict[str, str]:
    uid_to_path: dict[str, str] = {}

    for path in iter_files(root, include_legacy):
        if path.suffix == ".uid":
            uid = path.read_text(encoding="utf-8", errors="ignore").strip()
            if uid.startswith("uid://"):
                target = path.with_suffix("")
                if target.exists():
                    uid_to_path[uid] = rel(target, root)
            continue

        if path.suffix in {".tscn", ".tres", ".gdshader"}:
            try:
                head = path.read_text(encoding="utf-8", errors="ignore")[:400]
            except OSError:
                continue
            match = SCENE_UID_RE.search(head)
            if match:
                uid_to_path[match.group(1)] = rel(path, root)

    return uid_to_path


def build_class_index(root: Path, include_legacy: bool) -> dict[str, str]:
    classes: dict[str, str] = {}
    for path in iter_files(root, include_legacy):
        if path.suffix != ".gd":
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        match = CLASS_NAME_RE.search(text)
        if match:
            classes[match.group(1)] = rel(path, root)
    return classes


def resolve_entry(raw: str, uid_to_path: dict[str, str], root: Path) -> str | None:
    raw = raw.strip()
    if raw.startswith("uid://"):
        return uid_to_path.get(raw)
    if raw.startswith("res://"):
        return normalize_res_path(raw, root)
    return None


def parse_project_roots(root: Path, uid_to_path: dict[str, str]) -> list[str]:
    project_file = root / "project.godot"
    if not project_file.exists():
        return list(ALWAYS_ROOT)

    text = project_file.read_text(encoding="utf-8", errors="ignore")
    roots: list[str] = list(ALWAYS_ROOT)

    main = MAIN_SCENE_RE.search(text)
    if main:
        resolved = resolve_entry(main.group(1), uid_to_path, root)
        if resolved:
            roots.append(resolved)

    for match in AUTOLOAD_RE.finditer(text):
        resolved = resolve_entry(match.group(2), uid_to_path, root)
        if resolved:
            roots.append(resolved)

    icon = ICON_RE.search(text)
    if icon:
        resolved = normalize_res_path(icon.group(1), root)
        if resolved:
            roots.append(resolved)

    return sorted(set(roots))


def extract_references(
    text: str,
    uid_to_path: dict[str, str],
    class_index: dict[str, str],
    root: Path,
) -> set[str]:
    found: set[str] = set()

    for raw in RES_PATH_RE.findall(text):
        normalized = normalize_res_path(raw, root)
        if normalized:
            found.add(normalized)

    for uid in UID_RE.findall(text):
        mapped = uid_to_path.get(uid)
        if mapped:
            found.add(mapped)

    for class_name, script_path in class_index.items():
        # Avoid matching substrings inside longer identifiers.
        if re.search(rf"\b{re.escape(class_name)}\b", text):
            found.add(script_path)

    return found


def crawl_reachable(
    root: Path,
    seeds: list[str],
    uid_to_path: dict[str, str],
    class_index: dict[str, str],
    include_legacy: bool,
) -> set[str]:
    reachable: set[str] = set()
    queue: deque[str] = deque(seeds)

    while queue:
        current = queue.popleft()
        if current in reachable:
            continue
        reachable.add(current)

        path = root / current
        if not path.exists() or not path.is_file():
            continue
        if path.suffix not in SEARCHABLE_SUFFIXES:
            continue

        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue

        for ref in extract_references(text, uid_to_path, class_index, root):
            if ref not in reachable:
                queue.append(ref)

    return reachable


def list_resources(root: Path, include_legacy: bool) -> list[str]:
    resources: list[str] = []
    for path in iter_files(root, include_legacy):
        if path.suffix in IGNORE_SUFFIXES:
            continue
        if path.name == "project.godot":
            continue
        if path.suffix.lower() in RESOURCE_SUFFIXES:
            resources.append(rel(path, root))
    return sorted(resources)


def list_archive_resources(root: Path) -> list[str]:
    archive_root = root / "legacy"
    if not archive_root.exists():
        return []
    resources: list[str] = []
    for path in archive_root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix in IGNORE_SUFFIXES:
            continue
        if path.suffix.lower() in RESOURCE_SUFFIXES:
            resources.append(rel(path, root))
    return sorted(resources)


def categorize_unused(unused: list[str]) -> dict[str, list[str]]:
    buckets: dict[str, list[str]] = {
        "scenes": [],
        "scripts": [],
        "shaders": [],
        "art": [],
        "assets": [],
        "video": [],
        "other": [],
    }
    for path in unused:
        if path.startswith("scenes/"):
            buckets["scenes"].append(path)
        elif path.startswith("scripts/") or path.endswith(".gd"):
            buckets["scripts"].append(path)
        elif path.startswith("shaders/") or path.endswith(".gdshader"):
            buckets["shaders"].append(path)
        elif path.startswith("art/"):
            buckets["art"].append(path)
        elif path.startswith("assets/"):
            buckets["assets"].append(path)
        elif path.startswith("video/"):
            buckets["video"].append(path)
        else:
            buckets["other"].append(path)
    return {k: v for k, v in buckets.items() if v}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--include-legacy",
        action="store_true",
        help="Include legacy/ in the reachability graph (default: report legacy separately).",
    )
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON.")
    parser.add_argument("--verbose", action="store_true", help="Print roots and reachable count.")
    parser.add_argument(
        "--extra-root",
        action="append",
        default=[],
        metavar="RES_PATH",
        help="Additional res:// path seed (repeatable), e.g. res://scenes/redaction_test.tscn",
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Path to Godot project root (default: parent of tools/).",
    )
    args = parser.parse_args()

    root: Path = args.project_root.resolve()
    if not (root / "project.godot").exists():
        print(f"error: no project.godot in {root}", file=sys.stderr)
        return 1

    uid_to_path = build_uid_index(root, include_legacy=args.include_legacy)
    class_index = build_class_index(root, include_legacy=args.include_legacy)
    seeds = parse_project_roots(root, uid_to_path)
    for extra in args.extra_root:
        resolved = resolve_entry(extra, uid_to_path, root)
        if resolved:
            seeds.append(resolved)
        else:
            print(f"warning: could not resolve extra root {extra!r}", file=sys.stderr)
    seeds = sorted(set(seeds))
    reachable = crawl_reachable(
        root, seeds, uid_to_path, class_index, include_legacy=args.include_legacy
    )

    all_resources = list_resources(root, include_legacy=args.include_legacy)
    unused = [p for p in all_resources if p not in reachable]
    archive_resources = list_archive_resources(root)
    archive_unused = [p for p in archive_resources if p not in reachable]

    if args.json:
        payload = {
            "project_root": str(root),
            "roots": seeds,
            "reachable_count": len(reachable),
            "unused": unused,
            "unused_by_category": categorize_unused(unused),
            "legacy": {
                "included_in_graph": args.include_legacy,
                "files": archive_resources,
                "unreachable_within_legacy": archive_unused,
            },
        }
        print(json.dumps(payload, indent=2))
        return 0

    if args.verbose:
        print(f"Project: {root}")
        print(f"Roots ({len(seeds)}):")
        for seed in seeds:
            print(f"  - {seed}")
        print(f"Reachable files: {len(reachable)}")
        print()

    print(f"UNUSED FILES ({len(unused)})")
    print("=" * 40)
    if not unused:
        print("(none)")
    else:
        for category, paths in categorize_unused(unused).items():
            print(f"\n[{category}]")
            for path in paths:
                print(f"  {path}")

    if not args.include_legacy and archive_resources:
        print()
        print(f"LEGACY/ ARCHIVE ({len(archive_resources)} files, excluded from graph)")
        print("=" * 40)
        for path in archive_resources:
            print(f"  {path}")

    print()
    print("Notes:")
    print("  - Reachability starts at main scene, autoloads, icon, and default_bus_layout.")
    print("  - class_name scripts are followed when the class name appears in source.")
    print("  - legacy/ is excluded unless you pass --include-legacy.")
    print("  - .uid and .import sidecars are never listed.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
