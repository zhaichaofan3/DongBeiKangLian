"""Check cleanup integrity, tracked payload, and common credential signatures."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'docs/maintenance/repository-20261016'


def sha(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def main():
    baseline = json.loads((REPORT / 'protected-files.json').read_text())
    runtime = [item for item in baseline if not item['path'].endswith('.md')]
    changed = [item['path'] for item in runtime
               if not (ROOT / item['path']).is_file() or sha(ROOT / item['path']) != item['sha256']]
    migrated = json.loads((REPORT / 'model-migrations.json').read_text())
    bad_moves = [item['target'] for item in migrated if sha(ROOT / item['target']) != item['sha256']]
    raw = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT)
    files = [name.decode('utf-8') for name in raw.split(b'\0') if name]
    forbidden = [name for name in files if name.startswith(('WorkBackups/', 'Release/', 'ConversationBackups/',
                  'GodotProject/.godot/', '.auto-resume/', 'tools/asset_python/'))]
    secret = re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|sk-[A-Za-z0-9_-]{32,}|xox[baprs]-[A-Za-z0-9-]{20,}|-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----)')
    suspects = []
    for name in files:
        path = ROOT / name
        if path.suffix.lower() in {'.md', '.txt', '.json', '.jsonl', '.py', '.ps1', '.gd', '.html', '.ini', '.cfg'}:
            if secret.search(path.read_bytes()):
                suspects.append(name)
    lfs = subprocess.check_output(['git', 'lfs', 'ls-files', '--size'], cwd=ROOT, text=True)
    result = dict(protected_runtime_files=len(runtime), changed_runtime_files=changed,
                  model_inputs_verified=len(migrated), failed_model_migrations=bad_moves,
                  tracked_files=len(files), forbidden_tracked_files=forbidden,
                  credential_signature_files=suspects, lfs_files=len(lfs.splitlines()))
    result['passed'] = not any([changed, bad_moves, forbidden, suspects])
    (REPORT / 'repository-validation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))
    raise SystemExit(0 if result['passed'] else 1)


if __name__ == '__main__':
    main()
