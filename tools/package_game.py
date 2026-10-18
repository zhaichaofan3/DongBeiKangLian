"""Package an already validated Windows runtime; never rebuild or alter its PCK."""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RELEASE = ROOT / 'Release'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def verify_payload(directory, expected):
    actual = {p.relative_to(directory).as_posix() for p in directory.rglob('*') if p.is_file()}
    if actual != set(expected) | {'SHA256SUMS.txt'}:
        raise RuntimeError('Unexpected or missing payload files: ' + str(actual ^ (set(expected) | {'SHA256SUMS.txt'})))
    for name, checksum in expected.items():
        if digest(directory / name) != checksum:
            raise RuntimeError('Payload hash mismatch: ' + name)


def package(args):
    version = re.search(r'^config/version="([\w.\-]+)"$',
                        (ROOT / 'GodotProject/project.godot').read_text(encoding='utf-8'), re.M)[1]
    validation = json.loads((RELEASE / 'release_validation.json').read_text(encoding='utf-8-sig'))
    pack_hash = digest(RELEASE / 'FenghuoEcho.pck')
    if not validation.get('passed') or validation['version'] != version or validation['pack_sha256'] != pack_hash:
        raise RuntimeError('The runtime pack must match its successful game validation before packaging.')
    for entry in validation.get('scripts', []):
        if digest(ROOT / entry['path']) != entry['sha256']:
            raise RuntimeError('Game source changed since validation: ' + entry['path'])
    compiler = Path(args.iscc).resolve(strict=True)
    language = Path(args.language).resolve(strict=True)
    output = (ROOT / args.output / version).resolve()
    stage = ROOT / '.publish' / ('player-payload-' + version)
    if stage.exists():
        raise RuntimeError('Staging folder already exists; inspect it before retrying: ' + str(stage))
    stage.mkdir(parents=True)
    output.mkdir(parents=True, exist_ok=True)

    selected = ['FenghuoEcho.exe', 'FenghuoEcho.pck', 'ASSET_SOURCES.md', 'AUDIO_CREDITS.md',
                'GODOT_LICENSE.txt', 'GODOT_COPYRIGHT.txt', 'release_validation.json']
    selected += [p.relative_to(RELEASE).as_posix() for folder in ['AssetNotices', 'Dialogue']
                 for p in sorted((RELEASE / folder).rglob('*')) if p.is_file()]
    for name in selected:
        source, target = RELEASE / name, stage / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.suffix in {'.exe', '.pck'}:
            target.hardlink_to(source)
        else:
            shutil.copy2(source, target)
    for name in ['README.md', 'KNOWN_ISSUES.md', 'INSTALL.txt']:
        shutil.copy2(ROOT / 'docs/player' / name, stage / name)
    # BOM lets Windows Notepad recognize the Chinese player guide reliably.
    (stage / 'README.txt').write_text((stage / 'README.md').read_text(encoding='utf-8'), encoding='utf-8-sig')
    expected = {p.relative_to(stage).as_posix(): digest(p) for p in sorted(stage.rglob('*')) if p.is_file()}
    (stage / 'SHA256SUMS.txt').write_text(''.join(f'{value}  {name}\n' for name, value in expected.items()), encoding='utf-8')
    verify_payload(stage, expected)
    print(json.dumps({'stage_ready': True, 'files': len(expected) + 1, 'version': version}), flush=True)

    archive = output / f'FenghuoEcho-{version}-Portable-Windows-x64.zip'
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=3, allowZip64=True) as target:
        for name in sorted([*expected, 'SHA256SUMS.txt']):
            target.write(stage / name, 'FenghuoEcho/' + name)
    with zipfile.ZipFile(archive) as source:
        if set(source.namelist()) != {'FenghuoEcho/' + n for n in [*expected, 'SHA256SUMS.txt']}:
            raise RuntimeError('Archive contains unexpected files.')
        for name, checksum in expected.items():
            with source.open('FenghuoEcho/' + name) as stream:
                if hashlib.file_digest(stream, 'sha256').hexdigest() != checksum:
                    raise RuntimeError('Archive hash mismatch: ' + name)
    print('Portable archive: every file hash verified.', flush=True)
    subprocess.run([str(compiler), '/Qp', '/DPayloadDir=' + str(stage), '/DOutputDir=' + str(output),
                    '/DGameVersion=' + version, '/DChineseLanguage=' + str(language),
                    str(ROOT / 'tools/installer/FenghuoEcho.iss')], check=True)
    installer = output / f'FenghuoEcho-{version}-Setup-Windows-x64.exe'
    for artifact in [installer, archive]:
        if artifact.stat().st_size >= 1_000_000_000:
            raise RuntimeError('Player download exceeds the 1 GB budget: ' + artifact.name)
    artifacts = [installer, archive]
    for name in ['README.md', 'README.txt']:
        shutil.copy2(stage / name, output / name)
        artifacts.append(output / name)
    entries = [dict(name=p.name, bytes=p.stat().st_size, sha256=digest(p)) for p in artifacts]
    (output / 'SHA256SUMS.txt').write_text(''.join(f"{e['sha256']}  {e['name']}\n" for e in entries), encoding='utf-8')
    record = dict(version=version, created_at=datetime.now(timezone.utc).isoformat(),
                  game_pack_sha256=pack_hash, runtime_sha256=expected['FenghuoEcho.exe'],
                  source_revision=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  compiler_sha256=digest(compiler), language_sha256=digest(language),
                  payload=expected, payload_files=len(expected) + 1,
                  payload_bytes=sum((stage / n).stat().st_size for n in [*expected, 'SHA256SUMS.txt']),
                  download_budget_bytes=1_000_000_000,
                  archive_verified=True, installation_verified=False, artifacts=entries)
    write_json(output / 'distribution_manifest.json', record)
    # Remove only files created above, after both distribution formats succeed.
    for name in [*expected, 'SHA256SUMS.txt']:
        (stage / name).unlink()
    for folder in sorted((p for p in stage.rglob('*') if p.is_dir()), key=lambda p: len(p.parts), reverse=True):
        folder.rmdir()
    stage.rmdir()
    print(json.dumps({'output': str(output), 'artifacts': entries}, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iscc', required=True)
    parser.add_argument('--language', required=True)
    parser.add_argument('--output', default='Release/Distributions')
    package(parser.parse_args())
