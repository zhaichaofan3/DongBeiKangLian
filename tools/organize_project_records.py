"""Move old root-level notes aside and plan removal of retired one-off tools."""
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'docs/maintenance/repository-20261016'
CURRENT = {'README.md', 'WORKFLOW.md', 'DEVELOPMENT.md', 'DESIGN.md', 'PROJECT_HISTORY.md'}
moves = []
for source in sorted((ROOT / 'docs').glob('*.md')):
    if source.name in CURRENT:
        continue
    target = ROOT / 'docs/archive/design-notes' / source.name
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        raise RuntimeError(f'Destination exists: {target}')
    moves.append(dict(source=source.relative_to(ROOT).as_posix(), target=target.relative_to(ROOT).as_posix()))
    os.replace(source, target)
(REPORT / 'document-migrations.json').write_text(json.dumps(moves, indent=2) + '\n', encoding='utf-8')

paths = set()
for pattern in ['archive_*.py', 'finalize_*.py', 'generate_handover*.py', 'test_auto_resume*.py']:
    paths.update((ROOT / 'tools').glob(pattern))
for name in [
    'build_s02_inventory.py', 'build_s04_narration.py', 'build_s05_dialogue.py',
    'build_s06_storyboard.py', 'build_s07_opening_data.py', 'build_s08_plan.py',
    'build_s09_evidence.py', 'audit_s03_interfaces.py', 'verify_handover.py',
    'Organize-Workspace.ps1', 'workspace_maintenance.py', 'generate_handover_support.py',
    'diagnose_model_connection.py', 'blender-mirror-index.html', 'migrate_first_level_qa.py',
]:
    paths.add(ROOT / 'tools' / name)
for pattern in ['auto_resume*.json', 'checkpoint_tool_validation.json', 'production_plan_validation.json']:
    paths.update((ROOT / 'docs').glob(pattern))
items = [dict(path=path.relative_to(ROOT).as_posix(), bytes=path.stat().st_size,
              reason='Retired one-off step controller, old state generator or superseded batch finalizer')
         for path in sorted(paths) if path.is_file()]
(REPORT / 'retired-tools-plan.json').write_text(json.dumps(dict(items=items), indent=2) + '\n', encoding='utf-8')
print(json.dumps(dict(notes_moved=len(moves), retired_files=len(items))))
