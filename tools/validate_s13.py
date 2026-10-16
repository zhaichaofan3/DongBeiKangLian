"""Repeat S13 probes and mission regression, retaining every run's evidence."""
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / 'tools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
OUTPUT = ROOT / 'docs/level/S13' / (sys.argv[1] if len(sys.argv) > 1 else 'accepted')
OUTPUT.mkdir(parents=True, exist_ok=False)
CASES = [
    ('navigation', 's13_navigation', 'S13 NAVIGATION: PASS'),
    ('geometry', 's09_geometry', 'S09 GEOMETRY: PASS'),
    ('direct', 's09_route', 'S09 ROUTE direct: PASS'),
    ('skip', 's09_route', 'S09 ROUTE skip: PASS'),
    ('full', 's09_route', 'S09 ROUTE full: PASS'),
    ('smoke', 'smoke', 'SMOKE RESULT: 107/107 passed'),
    ('linear-route', 'linear_route', 'LINEAR ROUTE RESULT: 37/37 passed'),
    ('combat-route', 'combat_route', 'ACTIVE COMBAT ROUTE: PASS'),
    ('visual-motion', 'visual_motion', 'VISUAL MOTION RESULT: 50/50 passed'),
    ('story-moments', 'story_moments', 'STORY MOMENTS RESULT: 11/11 passed'),
    ('character-model', 'character_model', 'CHARACTER MODEL RESULT: 37/37 passed'),
]
results = []
for name, script, marker in CASES:
    folder = OUTPUT / name
    folder.mkdir()
    env = dict(os.environ, FENGHUO_S13_EVIDENCE=str(folder),
               FENGHUO_S09_EVIDENCE=str(folder), FENGHUO_S09_CASE=name)
    command = [str(ENGINE), '--headless', '--path', str(ROOT / 'GodotProject'),
               '--fixed-fps', '60', '--log-file', str(folder / 'runtime.log'),
               '--script', f'res://tests/{script}.gd', '--', '--qa']
    try:
        run = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                             text=True, encoding='utf-8', errors='replace', timeout=90)
        output = run.stdout + run.stderr
        success = run.returncode == 0 and marker in output and not re.search(r'^(?:SCRIPT ERROR|ERROR):', output, re.M)
        code = run.returncode
    except subprocess.TimeoutExpired as exc:
        output = str(exc)
        success, code = False, -1
    (folder / 'console.txt').write_text(output, encoding='utf-8')
    results.append({'case': name, 'script': script, 'passed': success, 'exit_code': code,
                    'marker': marker, 'warnings': [s for s in output.splitlines() if 'WARNING:' in s]})
    report = {'step': 'S13', 'timestamp': datetime.now().astimezone().isoformat(),
              'all_passed': len(results) == len(CASES) and all(r['passed'] for r in results), 'results': results}
    (OUTPUT / 'summary.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'{name}: {"PASS" if success else "FAIL"}', flush=True)
    if not success:
        print(output[-6000:], flush=True)
        break
sys.exit(0 if report['all_passed'] else 1)
