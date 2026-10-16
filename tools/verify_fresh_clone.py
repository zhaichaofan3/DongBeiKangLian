"""Fetch runtime assets from GitHub into an empty checkout and run Godot checks."""
import json
import argparse
import hashlib
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'docs/maintenance/repository-20261016'
CLONE = ROOT / '.publish/fresh-clone'


def run(command, log, cwd=ROOT):
    with (REPORT / log).open('w', encoding='utf-8') as output:
        result = subprocess.run(command, cwd=cwd, stdout=output, stderr=subprocess.STDOUT, timeout=1200)
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}); see {log}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--resume', action='store_true')
    arguments = parser.parse_args()
    if CLONE.exists() and not arguments.resume:
        raise RuntimeError('Refusing to overwrite an existing verification checkout')
    proxy = subprocess.run(['git', 'config', '--get', 'http.proxy'], cwd=ROOT, text=True, capture_output=True).stdout.strip()
    git_options = ['-c', 'http.proxy=' + proxy] if proxy else []
    if not arguments.resume:
        run(['git'] + git_options + ['clone', '--no-checkout',
             'https://github.com/zhaichaofan3/DongBeiKangLian.git', str(CLONE)], 'clone.log')
        if proxy:
            run(['git', 'config', 'http.proxy', proxy], 'clone-config.log', CLONE)
        run(['git', 'sparse-checkout', 'set', 'GodotProject'], 'clone-sparse.log', CLONE)
        # An empty checkout forces the LFS client to fetch the selected assets remotely.
        run(['git', 'checkout', 'main'], 'clone-checkout.log', CLONE)
    else:
        remote = subprocess.check_output(['git', 'remote', 'get-url', 'origin'], cwd=CLONE, text=True).strip()
        if remote != 'https://github.com/zhaichaofan3/DongBeiKangLian.git':
            raise RuntimeError('Unexpected verification checkout origin')
    lfs = json.loads(subprocess.check_output(['git', 'lfs', 'ls-files', '--json'], cwd=CLONE, text=True, encoding='utf-8'))['files']
    selected = [item for item in lfs if item['name'].startswith('GodotProject/')]
    for item in selected:
        with (CLONE / item['name']).open('rb') as source:
            if hashlib.file_digest(source, 'sha256').hexdigest() != item['oid']:
                raise RuntimeError('Downloaded LFS content mismatch: ' + item['name'])
    engine = os.environ.get('GODOT_EXE', str(ROOT / 'tools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'))
    project = CLONE / 'GodotProject'
    import_log = 'clone-import-retry.log' if arguments.resume else 'clone-import.log'
    run([engine, '--headless', '--path', str(project), '--import'], import_log)
    run([engine, '--headless', '--path', str(project), '--fixed-fps', '60', '--script', 'res://tests/smoke.gd',
         '--', '--qa'], 'clone-smoke.log')
    text = (REPORT / 'clone-smoke.log').read_text(encoding='utf-8')
    passed = 'SMOKE RESULT: 108/108 passed' in text and not any(line.startswith(('ERROR:', 'SCRIPT ERROR:')) for line in text.splitlines())
    result = dict(remote='https://github.com/zhaichaofan3/DongBeiKangLian',
                  commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=CLONE, text=True).strip(),
                  fresh_runtime_lfs_download=True, lfs_files_verified=len(selected), clean_import_passed=True,
                  initial_import_crashed=(REPORT / 'clone-import-failure-1.log').exists(), import_log=import_log,
                  smoke_passed=passed, smoke_assertions=108 if passed else 0)
    (REPORT / 'fresh-clone-validation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result), flush=True)
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
