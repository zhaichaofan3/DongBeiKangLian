"""Serial asset-focused checks for the 0.7.3 delivery; never asserts full regression."""
import argparse
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from package_game import ROOT, RELEASE, digest, write_json

REPORT = ROOT / 'docs/size_optimization_20261018'
ENGINE = ROOT / 'tools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
GROUPS = [
    ('delivery_assets', 'DELIVERY ASSETS: PASS'),
    ('smoke', 'SMOKE RESULT: 108/108 passed'),
    ('first_level_rebuild', 'FIRST LEVEL REBUILD: PASS'),
    ('courtyard_controls', 'COURTYARD CONTROLS: PASS'),
    ('river_journey', 'RIVER JOURNEY: PASS'),
    ('opening', 'OPENING RESULT: 41/41 passed'),
    ('navigation_budget', 'NAVIGATION BUDGET:'),
    ('render_quality', 'RENDER QUALITY: PASS'),
    ('world_revision', 'WORLD REVISION: PASS'),
]


def verify(source=False):
    folder = REPORT / ('source' if source else 'release')
    folder.mkdir(parents=True, exist_ok=True)
    environment = dict(os.environ)
    environment.update(FENGHUO_DELIVERY_ALIASES=str(ROOT / 'GodotProject/tools/texture_aliases.json'),
                       FENGHUO_DELIVERY_PACK='0' if source else '1',
                       FENGHUO_NAVIGATION_OUTPUT=str(folder / 'navigation.json'),
                       FENGHUO_NAVIGATION_REFERENCE=str(ROOT / 'docs/entry_sprint_20261017/release-navigation.json'),
                       FENGHUO_WORLD_EVIDENCE=str(folder / 'world'),
                       FENGHUO_OPENING_EVIDENCE=str(folder / 'opening'),
                       FENGHUO_RIVER_EVIDENCE=str(folder / 'river'),
                       FENGHUO_EXPANSION_EVIDENCE=str(folder / 'first-level'))
    for name in ['world', 'opening', 'river', 'first-level']:
        (folder / name).mkdir(exist_ok=True)
    results = []
    groups = GROUPS[:1] if source else GROUPS
    for fixture, marker in groups:
        rendered = fixture in ['render_quality', 'world_revision']
        command = [str(ENGINE), '--path', str(ROOT / 'GodotProject')] if source else [str(ENGINE), '--main-pack', str(RELEASE / 'FenghuoEcho.pck')]
        if not rendered:
            command += ['--headless']
        command += ['--fixed-fps', '60', '--resolution', '1280x720', '--script',
                    str(ROOT / 'GodotProject/tests' / (fixture + '.gd')), '--', '--qa']
        log = folder / (fixture + '.log')
        with log.open('w', encoding='utf-8') as stream:
            process = subprocess.run(command, cwd=os.environ['TEMP'], env=environment,
                                     stdout=stream, stderr=subprocess.STDOUT, timeout=480)
        content = log.read_text(encoding='utf-8-sig')
        if process.returncode or marker not in content or re.search(r'(?m)^(SCRIPT ERROR|ERROR|FAIL):', content):
            raise RuntimeError('Size release verification failed: ' + str(log))
        result = dict(name=fixture, rendered=rendered, exit_code=process.returncode,
                      log=str(log.relative_to(ROOT)), sha256=digest(log),
                      result=next(line for line in content.splitlines() if marker in line))
        results.append(result)
        print(json.dumps(result), flush=True)
    write_json(folder / 'checks.json', results)
    if source:
        return
    protected = json.loads((ROOT / 'docs/maintenance/repository-20261016/protected-files.json').read_text(encoding='utf-8-sig'))
    protected = [entry for entry in protected if entry['path'].startswith(('GodotProject/assets/audio/', 'GodotProject/assets/first_person/'))]
    for entry in protected:
        if digest(ROOT / entry['path']) != entry['sha256']:
            raise RuntimeError('A protected original asset changed: ' + entry['path'])
    # Every project file involved in loading or exporting resources is pinned.
    paths = [ROOT / 'GodotProject/project.godot', ROOT / 'GodotProject/export_presets.cfg']
    paths += [p for p in (ROOT / 'GodotProject').rglob('*') if p.is_file() and '.godot' not in p.parts
              and (p.suffix in {'.gd', '.gdshader', '.import'} or p.name in {'opening.json', 'texture_aliases.json'})]
    record = dict(passed=True, status='asset_and_targeted_checks_passed', version='0.7.3-rc1',
                  checked_at=datetime.now(timezone.utc).isoformat(), pack_sha256=digest(RELEASE / 'FenghuoEcho.pck'),
                  source_groups=1, package_groups=len(results), full_regression_repeated=False,
                  protected_original_assets_verified=len(protected),
                  logs=results, scripts=[dict(path=str(p.relative_to(ROOT)).replace('\\', '/'), sha256=digest(p)) for p in sorted(set(paths))],
                  limitations=['No new full combat or cross-hardware performance acceptance.',
                               'Prior ferry long frame is still unresolved.'])
    write_json(RELEASE / 'release_validation.json', record)
    write_json(REPORT / 'game-validation.json', record)
    print('Size-focused package validation recorded.', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', action='store_true')
    verify(parser.parse_args().source)
