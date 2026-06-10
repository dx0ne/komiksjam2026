#!/usr/bin/env python3
"""Generate Potty Secret SFX from tools/sound_effects_manifest.json via ElevenLabs.

Usage:
    set ELEVENLABS_API_KEY=your_key_here
    python tools/generate_sfx.py --dry-run
    python tools/generate_sfx.py --priority mvp
    python tools/generate_sfx.py --ids G1,G7,P1
    python tools/generate_sfx.py --api-key sk-... --force

Manifest: tools/sound_effects_manifest.json (exported from design/features.md).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

API_URL = "https://api.elevenlabs.io/v1/sound-generation"
MAX_PROMPT_CHARS = 450  # ElevenLabs sound-generation text limit
MIN_DURATION_S = 0.5
MAX_DURATION_S = 30.0
DEFAULT_MANIFEST = Path(__file__).resolve().parent / "sound_effects_manifest.json"
DEFAULT_REPORT = Path(__file__).resolve().parent / "sfx_generation_report.json"
DEFAULT_STATUS = Path(__file__).resolve().parent / "sfx_generation_status.json"
DEFAULT_STATUS_TXT = Path(__file__).resolve().parent / "sfx_generation_status.txt"
PRIORITY_ORDER = ("mvp", "atmosphere", "polish")
PROJECT_ROOT = Path(__file__).resolve().parent.parent


def load_manifest(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def filter_sounds(
    sounds: list[dict],
    ids: set[str] | None,
    priority: str | None,
    category: str | None,
    *,
    include_procedural: bool = False,
) -> list[dict]:
    out: list[dict] = []
    for sound in sounds:
        if sound.get("procedural") and not include_procedural:
            continue
        if ids and sound["id"] not in ids:
            continue
        if priority and sound.get("priority") != priority:
            continue
        if category and sound.get("category") != category:
            continue
        out.append(sound)
    return out


def normalize_duration(raw: float | int | None) -> float | None:
    if raw is None:
        return None
    value = float(raw)
    return max(MIN_DURATION_S, min(MAX_DURATION_S, value))


def parse_api_error(err_body: str) -> str:
    try:
        payload = json.loads(err_body)
    except json.JSONDecodeError:
        return err_body
    detail = payload.get("detail")
    if isinstance(detail, dict):
        return detail.get("message") or detail.get("code") or err_body
    if isinstance(detail, list) and detail:
        first = detail[0]
        if isinstance(first, dict):
            return first.get("msg", err_body)
    return err_body


def write_report(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")


def load_last_errors(report_path: Path) -> dict[str, str]:
    if not report_path.is_file():
        return {}
    try:
        report = json.loads(report_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    errors: dict[str, str] = {}
    for entry in report.get("results", []):
        if entry.get("status") == "failed" and entry.get("id"):
            errors[entry["id"]] = entry.get("error", "")
    return errors


def audit_sounds(sounds: list[dict], report_path: Path) -> dict:
    last_errors = load_last_errors(report_path)
    generated: list[dict] = []
    missing: list[dict] = []

    for sound in sounds:
        if sound.get("procedural"):
            entry = {
                "id": sound["id"],
                "name": sound["name"],
                "priority": sound.get("priority", ""),
                "category": sound.get("category", ""),
                "output_path": sound.get("output_path"),
                "procedural": True,
            }
            generated.append(entry)
            continue
        output_path = sound.get("output_path")
        if not output_path:
            continue
        out_path = PROJECT_ROOT / output_path
        entry = {
            "id": sound["id"],
            "name": sound["name"],
            "priority": sound.get("priority", ""),
            "category": sound.get("category", ""),
            "output_path": output_path,
        }
        if out_path.is_file():
            entry["bytes"] = out_path.stat().st_size
            generated.append(entry)
        else:
            if sound["id"] in last_errors:
                entry["last_error"] = last_errors[sound["id"]]
            missing.append(entry)

    by_priority: dict[str, dict[str, int]] = {}
    for sound in sounds:
        if sound.get("procedural"):
            continue
        tier = sound.get("priority", "other")
        bucket = by_priority.setdefault(tier, {"total": 0, "generated": 0, "missing": 0})
        bucket["total"] += 1
        output_path = sound.get("output_path")
        if output_path and (PROJECT_ROOT / output_path).is_file():
            bucket["generated"] += 1
        else:
            bucket["missing"] += 1

    return {
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "summary": {
            "total": len(sounds),
            "generated": len(generated),
            "missing": len(missing),
            "percent_complete": round(100 * len(generated) / len(sounds)) if sounds else 0,
            "by_priority": by_priority,
        },
        "generated": sorted(generated, key=lambda e: e["id"]),
        "missing": sorted(missing, key=lambda e: e["id"]),
    }


def format_status_text(inventory: dict, *, filter_label: str | None) -> str:
    lines: list[str] = []
    summary = inventory["summary"]
    lines.append("Potty Secret - sound generation inventory")
    lines.append("=" * 44)
    lines.append(
        f"Progress: {summary['generated']}/{summary['total']} generated "
        f"({summary['percent_complete']}%)"
    )
    if filter_label:
        lines.append(f"Filter: {filter_label}")
    lines.append("")

    for tier in PRIORITY_ORDER:
        bucket = summary["by_priority"].get(tier)
        if not bucket:
            continue
        lines.append(f"[{tier.upper()}] {bucket['generated']}/{bucket['total']} done")
        tier_missing = [m for m in inventory["missing"] if m.get("priority") == tier]
        if tier_missing:
            for item in tier_missing:
                err = item.get("last_error")
                suffix = f"  <- {err}" if err else ""
                lines.append(f"  TODO  {item['id']:12} {item['name']}{suffix}")
        else:
            lines.append("  (complete)")
        lines.append("")

    other_tiers = [t for t in summary["by_priority"] if t not in PRIORITY_ORDER]
    for tier in other_tiers:
        bucket = summary["by_priority"][tier]
        lines.append(f"[{tier.upper()}] {bucket['generated']}/{bucket['total']} done")

    lines.append("GENERATED")
    lines.append("-" * 44)
    if inventory["generated"]:
        for item in inventory["generated"]:
            tag = "PROC" if item.get("procedural") else "OK  "
            lines.append(f"  {tag}  {item['id']:12} {item['name']}")
    else:
        lines.append("  (none)")
    lines.append("")

    if inventory["missing"]:
        ids = ",".join(item["id"] for item in inventory["missing"])
        lines.append("Generate missing:")
        lines.append(f"  python tools/generate_sfx.py --ids {ids}")
    return "\n".join(lines) + "\n"


def write_status_files(
    inventory: dict,
    *,
    json_path: Path,
    txt_path: Path,
    filter_label: str | None,
) -> None:
    write_report(json_path, inventory)
    txt_path.write_text(format_status_text(inventory, filter_label=filter_label), encoding="utf-8")


def print_status(
    sounds: list[dict],
    report_path: Path,
    *,
    priority: str | None,
    status_json_path: Path,
    status_txt_path: Path,
) -> int:
    inventory = audit_sounds(sounds, report_path)
    filter_label = f"priority={priority}" if priority else None
    write_status_files(
        inventory,
        json_path=status_json_path,
        txt_path=status_txt_path,
        filter_label=filter_label,
    )

    print(format_status_text(inventory, filter_label=filter_label))
    print(f"Status files:")
    print(f"  {status_txt_path.relative_to(PROJECT_ROOT)}")
    print(f"  {status_json_path.relative_to(PROJECT_ROOT)}")
    if report_path.is_file():
        print(f"Last API run: {report_path.relative_to(PROJECT_ROOT)}")

    return 0 if not inventory["missing"] else 1


def build_prompt(sound: dict) -> str:
    """Return the API prompt. Manifest entries must stay within MAX_PROMPT_CHARS."""
    prompt = sound["prompt"].strip()
    if len(prompt) > MAX_PROMPT_CHARS:
        raise ValueError(
            f"[{sound['id']}] prompt is {len(prompt)} chars; "
            f"ElevenLabs max is {MAX_PROMPT_CHARS}"
        )
    return prompt


def generate_one(
    *,
    api_key: str,
    text: str,
    loop: bool,
    duration_seconds: float | None,
    prompt_influence: float,
    output_format: str,
    timeout: float,
) -> bytes:
    body: dict = {
        "text": text,
        "loop": loop,
        "prompt_influence": prompt_influence,
        "model_id": "eleven_text_to_sound_v2",
    }
    if duration_seconds is not None:
        body["duration_seconds"] = normalize_duration(duration_seconds)

    url = f"{API_URL}?output_format={output_format}"
    data = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate game SFX with ElevenLabs.")
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help="Path to sound_effects_manifest.json",
    )
    parser.add_argument(
        "--api-key",
        default=os.environ.get("ELEVENLABS_API_KEY", ""),
        help="ElevenLabs API key (or set ELEVENLABS_API_KEY)",
    )
    parser.add_argument("--ids", default="", help="Comma-separated sound IDs, e.g. G1,G7,A1")
    parser.add_argument("--priority", choices=["mvp", "atmosphere", "polish"], default="")
    parser.add_argument("--category", default="", help="Filter by category field")
    parser.add_argument("--dry-run", action="store_true", help="List sounds without calling API")
    parser.add_argument(
        "--status",
        action="store_true",
        help="Inventory: what exists vs still TODO (writes tools/sfx_generation_status.txt)",
    )
    parser.add_argument(
        "--status-json",
        type=Path,
        default=DEFAULT_STATUS,
        help="JSON inventory output for --status (default: tools/sfx_generation_status.json)",
    )
    parser.add_argument(
        "--status-txt",
        type=Path,
        default=DEFAULT_STATUS_TXT,
        help="Readable inventory for --status (default: tools/sfx_generation_status.txt)",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=DEFAULT_REPORT,
        help="Where to write JSON run report (default: tools/sfx_generation_report.json)",
    )
    parser.add_argument("--force", action="store_true", help="Regenerate even if output exists")
    parser.add_argument("--delay", type=float, default=1.0, help="Seconds between API calls")
    parser.add_argument("--prompt-influence", type=float, default=0.45, help="0–1, higher = more literal")
    parser.add_argument(
        "--output-format",
        default="mp3_44100_128",
        help="ElevenLabs output_format query param",
    )
    parser.add_argument("--timeout", type=float, default=120.0, help="HTTP timeout per request")
    args = parser.parse_args()

    if not args.manifest.is_file():
        print(f"Manifest not found: {args.manifest}", file=sys.stderr)
        return 1

    manifest = load_manifest(args.manifest)
    sounds = manifest.get("sounds", [])
    if not sounds:
        print("No sounds in manifest.", file=sys.stderr)
        return 1

    id_filter = {s.strip() for s in args.ids.split(",") if s.strip()} or None
    category_filter = args.category.strip() or None
    priority_filter = args.priority or None
    selected = filter_sounds(sounds, id_filter, priority_filter, category_filter)

    if not selected:
        print("No sounds matched filters.", file=sys.stderr)
        return 1

    try:
        for sound in selected:
            build_prompt(sound)
    except ValueError as exc:
        print(exc, file=sys.stderr)
        return 1

    if args.status:
        return print_status(
            selected,
            args.report,
            priority=priority_filter,
            status_json_path=args.status_json,
            status_txt_path=args.status_txt,
        )

    if args.dry_run:
        print(f"Would generate {len(selected)} sound(s):\n")
        for sound in selected:
            out = PROJECT_ROOT / sound["output_path"]
            exists = "exists" if out.is_file() else "missing"
            text = build_prompt(sound)
            print(
                f"  [{sound['id']}] {sound['name']} -> {sound['output_path']} "
                f"({exists}, {len(text)} chars)"
            )
            print(f"       {text[:120]}...")
        return 0

    if not args.api_key:
        print(
            "Missing API key. Set ELEVENLABS_API_KEY or pass --api-key.",
            file=sys.stderr,
        )
        return 1

    results: list[dict] = []
    ok = 0
    skipped = 0
    failed = 0

    for i, sound in enumerate(selected):
        if sound.get("procedural"):
            print(f"[{sound['id']}] skip (procedural): {sound.get('implementation', 'runtime')}")
            skipped += 1
            results.append(
                {
                    "id": sound["id"],
                    "name": sound["name"],
                    "status": "skipped",
                    "reason": "procedural",
                }
            )
            continue

        output_path = sound.get("output_path")
        if not output_path:
            print(f"[{sound['id']}] skip (no output_path)", file=sys.stderr)
            skipped += 1
            continue
        out_path = PROJECT_ROOT / output_path
        out_path.parent.mkdir(parents=True, exist_ok=True)
        rel_out = str(out_path.relative_to(PROJECT_ROOT))

        if out_path.is_file() and not args.force:
            print(f"[{sound['id']}] skip (exists): {rel_out}")
            skipped += 1
            results.append(
                {
                    "id": sound["id"],
                    "name": sound["name"],
                    "status": "skipped",
                    "output_path": sound["output_path"],
                }
            )
            continue

        text = build_prompt(sound)
        duration = sound.get("duration_seconds")
        loop = bool(sound.get("loop", False))

        print(f"[{sound['id']}] generating {sound['name']} ...", flush=True)
        try:
            audio = generate_one(
                api_key=args.api_key,
                text=text,
                loop=loop,
                duration_seconds=duration,
                prompt_influence=args.prompt_influence,
                output_format=args.output_format,
                timeout=args.timeout,
            )
        except urllib.error.HTTPError as exc:
            err_body = exc.read().decode("utf-8", errors="replace")
            error = parse_api_error(err_body)
            print(f"  HTTP {exc.code}: {error}", file=sys.stderr)
            failed += 1
            results.append(
                {
                    "id": sound["id"],
                    "name": sound["name"],
                    "status": "failed",
                    "output_path": sound["output_path"],
                    "http_status": exc.code,
                    "error": error,
                }
            )
            continue
        except urllib.error.URLError as exc:
            error = str(exc)
            print(f"  Network error: {error}", file=sys.stderr)
            failed += 1
            results.append(
                {
                    "id": sound["id"],
                    "name": sound["name"],
                    "status": "failed",
                    "output_path": sound["output_path"],
                    "error": error,
                }
            )
            continue

        out_path.write_bytes(audio)
        print(f"  saved {rel_out} ({len(audio)} bytes)")
        ok += 1
        results.append(
            {
                "id": sound["id"],
                "name": sound["name"],
                "status": "ok",
                "output_path": sound["output_path"],
                "bytes": len(audio),
            }
        )

        if i < len(selected) - 1 and args.delay > 0:
            time.sleep(args.delay)

    report = {
        "summary": {
            "generated": ok,
            "skipped": skipped,
            "failed": failed,
            "total": len(selected),
        },
        "filters": {
            "ids": sorted(id_filter) if id_filter else None,
            "priority": priority_filter,
            "category": category_filter,
        },
        "results": results,
    }
    write_report(args.report, report)

    # Refresh full-manifest inventory so progress is always easy to read.
    full_inventory = audit_sounds(sounds, args.report)
    write_status_files(
        full_inventory,
        json_path=args.status_json,
        txt_path=args.status_txt,
        filter_label=None,
    )

    print(f"\nDone: {ok} generated, {skipped} skipped, {failed} failed.")
    print(f"Report: {args.report.relative_to(PROJECT_ROOT)}")
    print(
        f"Inventory: {full_inventory['summary']['generated']}/"
        f"{full_inventory['summary']['total']} on disk "
        f"({full_inventory['summary']['percent_complete']}%)"
    )
    print(f"  {args.status_txt.relative_to(PROJECT_ROOT)}")
    if failed:
        failed_ids = ",".join(r["id"] for r in results if r["status"] == "failed")
        print(f"Retry failed: python tools/generate_sfx.py --ids {failed_ids}")
    elif full_inventory["missing"]:
        missing_ids = ",".join(item["id"] for item in full_inventory["missing"])
        print(f"Still TODO: python tools/generate_sfx.py --ids {missing_ids}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
