"""Create a reviewable cleanup plan and preserve the current model inputs."""
import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'docs/maintenance/repository-20261016'
TEXT = {'.md', '.txt', '.log', '.json', '.jsonl', '.csv', '.html', '.srt', '.svg', '.xml', '.sha256'}
VISUALS = {
    'docs/river_journey_20261016/source-render-final/boarding.png',
    'docs/river_journey_20261016/source-render-final/river-wide.png',
    'docs/river_journey_20261016/source-render-final/forest-bend.png',
    'docs/river_journey_20261016/source-render-final/village-introduction.png',
    'docs/first_level_rebuild_20261016/source-render-final/logging-wide.png',
    'docs/first_level_rebuild_20261016/source-render-final/village-wide.png',
}


def digest(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def main():
    baseline = REPORT / 'protected-files.json'
    if not baseline.exists():
        files = []
        for path in (ROOT / 'GodotProject').rglob('*'):
            if path.is_file() and '.godot' not in path.parts:
                files.append(dict(path=path.relative_to(ROOT).as_posix(), bytes=path.stat().st_size, sha256=digest(path)))
        baseline.write_text(json.dumps(files, indent=2) + '\n', encoding='utf-8')

    migrations = []
    for old, new in [
        ('docs/expansion_20261015', 'AssetLibrary/environment/user_expansion_20261015/imported'),
        ('docs/user-models-20261015', 'AssetLibrary/characters/user_models_20261015/imported'),
    ]:
        for source in sorted((ROOT / old).glob('*/raw-import.blend')):
            target = ROOT / new / source.relative_to(ROOT / old)
            assert not target.exists(), target
            target.parent.mkdir(parents=True, exist_ok=True)
            record = dict(source=source.relative_to(ROOT).as_posix(), target=target.relative_to(ROOT).as_posix(),
                          bytes=source.stat().st_size, sha256=digest(source))
            os.replace(source, target)
            assert digest(target) == record['sha256']
            migrations.append(record)
    if migrations:
        (REPORT / 'model-migrations.json').write_text(json.dumps(migrations, indent=2) + '\n', encoding='utf-8')

    targets = {}
    def add(path, reason):
        path = ROOT / path if isinstance(path, str) else path
        if not path.exists():
            return
        relative = path.relative_to(ROOT).as_posix()
        size = sum(p.stat().st_size for p in path.rglob('*') if p.is_file()) if path.is_dir() else path.stat().st_size
        targets[relative] = dict(path=relative, bytes=size, reason=reason)

    for name in [
        '.models', '.auto-resume', 'tools/continuation', 'tools/.continuation-schema',
        'AssetLibrary/audio/the-free-firearm-sound-library',
        'AssetLibrary/characters/quaternius_ual1', 'AssetLibrary/characters/quaternius_ual2',
        'AssetLibrary/characters/godot_tps_player',
    ]:
        add(name, 'Unused development collection or retired automatic step controller')
    for name in [
        'Auto-Resume.vbs', 'Stop-Auto-Resume.cmd', 'tools/auto_resume.py',
        'tools/work_checkpoint.py', 'tools/Save-WorkCheckpoint.ps1',
        'tools/test_auto_resume.py', 'tools/test_auto_resume_live.py', 'tools/test_work_checkpoint.py',
        'docs/production_state.json', 'docs/work_history.jsonl', 'docs/AUTO_RESUME.md',
        'docs/RESUME_CURRENT.md', 'HANDOVER.md',
    ]:
        add(name, 'Old numbered step state and full-copy backup workflow retired by user request')
    for folder in ['docs', 'Release/Validation', 'ConversationBackups']:
        for path in (ROOT / folder).rglob('*'):
            if not path.is_file():
                continue
            relative = path.relative_to(ROOT).as_posix()
            if relative.startswith('docs/maintenance/repository-20261016/'):
                continue
            if relative in VISUALS:
                continue
            if path.suffix.lower() not in TEXT or path.stat().st_size > 2 * 1024**2:
                add(path, 'Repeated visual/binary evidence or oversized raw inventory; compact text evidence retained')
    # Retain only the base character and its actual glTF dependencies.
    base_dir = ROOT / 'AssetLibrary/characters/quaternius_base_characters'
    gltf = next(base_dir.rglob('Superhero_Male_FullBody.gltf'))
    data = json.loads(gltf.read_text(encoding='utf-8'))
    keep = {gltf.resolve()}
    for section in ['buffers', 'images']:
        for item in data.get(section, []):
            uri = item.get('uri', '')
            if uri and not uri.startswith('data:'):
                from urllib.parse import unquote
                keep.add((gltf.parent / unquote(uri)).resolve())
    for path in base_dir.rglob('*'):
        if path.is_file() and path.resolve() not in keep and path.suffix.lower() not in {'.md', '.txt', '.html', '.json'}:
            add(path, 'Unselected base character variant; selected glTF, dependencies and notices retained')
    items = [item for name, item in sorted(targets.items())
             if not any(name.startswith(parent + '/') for parent in targets if parent != name)]
    plan = dict(bytes_to_remove=sum(item['bytes'] for item in items), items=items,
                retained_visuals=sorted(VISUALS), protected_baseline=baseline.relative_to(ROOT).as_posix())
    (REPORT / 'resource-plan.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(targets=len(items), GiB_to_remove=round(plan['bytes_to_remove']/2**30, 3),
                          model_inputs_moved=len(migrations), protected_files=len(json.loads(baseline.read_text())))))


if __name__ == '__main__':
    main()
