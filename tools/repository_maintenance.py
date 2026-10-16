"""Inventory the workspace without following junctions or symlinks."""
import argparse
import heapq
import json
import os
import hashlib
from collections import Counter
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "docs/maintenance/repository-20261016"


def inventory(label):
    totals = Counter()
    counts = Counter()
    extensions = Counter()
    largest = []
    links, errors = [], []
    stack = [ROOT]
    while stack:
        directory = stack.pop()
        try:
            with os.scandir(directory) as entries:
                for entry in entries:
                    path = Path(entry.path)
                    relative = path.relative_to(ROOT).as_posix()
                    if relative == ".git" or relative.startswith(".git/"):
                        continue
                    try:
                        stat = entry.stat(follow_symlinks=False)
                        if entry.is_symlink() or getattr(stat, "st_file_attributes", 0) & 0x400:
                            links.append(relative)
                            continue
                        if entry.is_dir(follow_symlinks=False):
                            stack.append(path)
                            continue
                        if not entry.is_file(follow_symlinks=False):
                            continue
                        size = stat.st_size
                        parts = relative.split("/")
                        for depth in range(1, min(4, len(parts))):
                            prefix = "/".join(parts[:depth])
                            totals[prefix] += size
                            counts[prefix] += 1
                        totals["."] += size
                        counts["."] += 1
                        extensions[path.suffix.lower()] += size
                        heapq.heappush(largest, (size, relative))
                        if len(largest) > 150:
                            heapq.heappop(largest)
                    except OSError as error:
                        errors.append({"path": relative, "error": str(error)})
        except OSError as error:
            errors.append({"path": str(directory), "error": str(error)})
    git_bytes = sum(path.stat().st_size for path in (ROOT / '.git').rglob('*') if path.is_file()) if (ROOT / '.git').exists() else 0
    report = {
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "bytes": totals["."], "files": counts["."], "git_bytes": git_bytes,
        "total_bytes_including_git": totals["."] + git_bytes,
        "directories": [{"path": key, "bytes": value, "files": counts[key]}
                        for key, value in totals.most_common()],
        "extensions": dict(extensions.most_common()),
        "largest": [{"path": path, "bytes": size} for size, path in sorted(largest, reverse=True)],
        "links_skipped": links, "errors": errors,
    }
    REPORT.mkdir(parents=True, exist_ok=True)
    (REPORT / (label + ".json")).write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    summary = {"GiB": round(totals["."] / 2**30, 3), "git_GiB": round(git_bytes / 2**30, 3),
               "total_GiB_including_git": round((totals["."] + git_bytes) / 2**30, 3), "files": counts["."], "errors": errors,
               "top_level": [{"path": key, "GiB": round(value / 2**30, 3), "files": counts[key]}
                             for key, value in totals.most_common() if "/" not in key and key != "."],
               "largest": report["largest"][:25]}
    print(json.dumps(summary, ensure_ascii=False, indent=2))


def backup_plan():
    before = json.loads((REPORT / "before.json").read_text(encoding="utf-8"))
    sizes = {entry["path"]: entry["bytes"] for entry in before["directories"]}
    latest = (ROOT / "WorkBackups/LATEST.txt").read_text(encoding="utf-8-sig").strip()
    retained = ROOT / latest
    manifest = retained / "checkpoint.json"
    assert retained.parent == ROOT / "WorkBackups" and json.loads(manifest.read_text(encoding="utf-8"))["complete"]
    items = []
    history = []
    for directory in sorted((ROOT / "WorkBackups").iterdir()):
        if not directory.is_dir() or directory == retained:
            continue
        relative = directory.relative_to(ROOT).as_posix()
        record = directory / "checkpoint.json"
        if record.exists():
            state = json.loads(record.read_text(encoding="utf-8"))
            history.append({key: value for key, value in state.items()
                            if key not in {"files", "state", "work_history", "progress"}})
        items.append({"path": relative, "bytes": sizes.get(relative, 0), "reason": "Superseded full checkpoint; latest verified recovery retained"})
    for name in ["ReleaseBackups", "RestoreChecks", "tools/downloads", "GameProject", "AssetReview"]:
        if (ROOT / name).exists():
            items.append({"path": name, "bytes": sizes.get(name, 0), "reason": "Obsolete release/recovery experiment or reproducible installer; current project and release retained"})
    plan = {"retained_checkpoint": latest, "retained_manifest_sha256": hashlib.sha256(manifest.read_bytes()).hexdigest(),
            "bytes_to_remove": sum(entry["bytes"] for entry in items), "items": items}
    (REPORT / "backup-plan.json").write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (REPORT / "checkpoint-history.json").write_text(json.dumps(history, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"retained": latest, "directories_to_remove": len(items), "GiB_to_remove": round(plan["bytes_to_remove"] / 2**30, 3)}, ensure_ascii=False))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("label")
    label = parser.parse_args().label
    if label == "backup-plan":
        backup_plan()
    else:
        inventory(label)
