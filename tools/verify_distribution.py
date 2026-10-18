"""Install and launch the delivered artifacts, then uninstall the isolated QA copy."""
import argparse
import json
import os
import re
import subprocess
import winreg
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from package_game import ROOT, digest, verify_payload, write_json

UNINSTALL_KEY = r'Software\Microsoft\Windows\CurrentVersion\Uninstall\{2A8680CD-4EBD-4E71-BB8C-D52487A4CB27}_is1'
PLAYER_UNINSTALL_KEY = r'Software\Microsoft\Windows\CurrentVersion\Uninstall\{D72EA144-21F6-454B-A70D-DB2BED768092}_is1'


def registration(key_path=UNINSTALL_KEY):
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path) as key:
            return {name: winreg.QueryValueEx(key, name)[0] for name in ['DisplayName', 'DisplayVersion', 'InstallLocation']}
    except FileNotFoundError:
        return None


def run_game(executable, cwd, report, fixture, rendered=False):
    command = [str(executable), '--fixed-fps', '60']
    if not rendered:
        command.append('--headless')
    drivers = {'visual_motion': ROOT / 'tools/installer/distribution_motion.gd',
               'delivery_title': ROOT / 'tools/installer/distribution_title.gd'}
    driver = drivers[fixture] if rendered else ROOT / 'GodotProject/tests' / (fixture + '.gd')
    command += ['--resolution', '1280x720', '--script', str(driver), '--', '--qa']
    environment = dict(os.environ)
    environment['FENGHUO_MOTION_CAPTURE_DIR'] = str(report / 'installed-screenshots')
    log = report / (fixture + '.log')
    with log.open('w', encoding='utf-8') as stream:
        process = subprocess.run(command, cwd=cwd, env=environment, stdout=stream, stderr=subprocess.STDOUT, timeout=480)
    content = log.read_text(encoding='utf-8-sig')
    pattern = {'visual_motion': 'VISUAL MOTION RESULT:', 'delivery_title': 'DELIVERY TITLE RESULT:',
               'smoke': 'SMOKE RESULT:'}[fixture]
    match = re.search(re.escape(pattern) + r'\s*(\d+)/(\d+) passed', content)
    if process.returncode or not match or match[1] != match[2] or re.search(r'(?m)^(SCRIPT ERROR|ERROR|FAIL):', content):
        raise RuntimeError('Delivered executable failed verification: ' + str(log))
    result = dict(executable=str(executable.relative_to(ROOT)), rendered=rendered,
                  fixture=fixture, driver=str(driver.relative_to(ROOT)), driver_sha256=digest(driver),
                  checks=int(match[1]), exit_code=process.returncode, log_sha256=digest(log))
    print(json.dumps(result), flush=True)
    return result


def verify(directory, report):
    record = json.loads((directory / 'distribution_manifest.json').read_text(encoding='utf-8'))
    if registration():
        raise RuntimeError('A prior QA installation is registered; inspect it before retrying.')
    player_registration = registration(PLAYER_UNINSTALL_KEY)
    programs = Path(os.environ['APPDATA']) / 'Microsoft/Windows/Start Menu/Programs'
    player_shortcuts = {str(p): digest(p) for group in ['东北抗联 烽火回声', '烽火回声 · 林海归途']
                        for p in (programs / group).glob('*.lnk')}
    shortcut_folder = programs / '东北抗联 烽火回声 QA'
    if shortcut_folder.exists():
        raise RuntimeError('Existing product shortcuts must not be overwritten during QA.')
    for artifact in record['artifacts']:
        path = directory / artifact['name']
        if path.stat().st_size != artifact['bytes'] or digest(path) != artifact['sha256']:
            raise RuntimeError('Distribution artifact changed: ' + path.name)
    work = ROOT / '.publish' / ('distribution-qa-' + record['version'])
    if work.exists():
        raise RuntimeError('QA directory already exists; inspect before retrying: ' + str(work))
    work.mkdir(parents=True)
    report.mkdir(parents=True, exist_ok=True)
    install = work / '中文路径 安装测试'
    portable = work / '中文路径 解压测试'
    portable.mkdir()
    archive = next(directory.glob('*-Portable-Windows-x64.zip'))
    with zipfile.ZipFile(archive) as package:
        names = {'FenghuoEcho/' + name for name in [*record['payload'], 'SHA256SUMS.txt']}
        if set(package.namelist()) != names:
            raise RuntimeError('Unexpected archive paths.')
        package.extractall(portable)
    portable_game = portable / 'FenghuoEcho'
    verify_payload(portable_game, record['payload'])
    saves = Path(os.environ['APPDATA']) / 'FenghuoEcho'
    protected = {name: digest(saves / name) if (saves / name).exists() else None
                 for name in ['qinglan_checkpoint_v2.json', 'presentation_v1.cfg']}
    checks = []
    installed_ok = False
    try:
        checks.append(run_game(portable_game / 'FenghuoEcho.exe', work, report, 'smoke'))
        installer = next(directory.glob('*-Setup-Windows-x64.exe'))
        subprocess.run([str(installer), '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-',
                        '/DIR=' + str(install), '/TASKS=', '/DeliveryVerification=isolated',
                        '/LOG=' + str(report / 'install.log')], cwd=work, check=True, timeout=300)
        installed_ok = True
        installed_registration = registration()
        if (not installed_registration or installed_registration['DisplayVersion'] != record['version']
                or installed_registration['DisplayName'] != '东北抗联 烽火回声'):
            raise RuntimeError('Windows uninstall registration is missing or has the wrong version.')
        for name, checksum in record['payload'].items():
            if digest(install / name) != checksum:
                raise RuntimeError('Installed file hash mismatch: ' + name)
        if len(list(shortcut_folder.glob('*.lnk'))) != 3:
            raise RuntimeError('Expected game, player guide and uninstall shortcuts.')
        checks.append(run_game(install / 'FenghuoEcho.exe', work, report, 'visual_motion', rendered=True))
        checks.append(run_game(install / 'FenghuoEcho.exe', work, report, 'delivery_title', rendered=True))
        for name, checksum in record['payload'].items():
            if digest(install / name) != checksum:
                raise RuntimeError('Installed game modified a payload file: ' + name)
    finally:
        if installed_ok:
            subprocess.run([str(install / 'unins000.exe'), '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART',
                            '/LOG=' + str(report / 'uninstall.log')], cwd=work, check=True, timeout=180)
        for name, checksum in protected.items():
            path = saves / name
            if (digest(path) if path.exists() else None) != checksum:
                raise RuntimeError('A real player save or preference changed during QA: ' + name)
        if registration(PLAYER_UNINSTALL_KEY) != player_registration:
            raise RuntimeError('The player installation registration changed during QA.')
        current_shortcuts = {str(p): digest(p) for group in ['东北抗联 烽火回声', '烽火回声 · 林海归途']
                             for p in (programs / group).glob('*.lnk')}
        if current_shortcuts != player_shortcuts:
            raise RuntimeError('The player shortcuts changed during QA.')
    if registration() is not None or any((install / name).exists() for name in record['payload']) or shortcut_folder.exists():
        raise RuntimeError('Uninstall left payload files, registration or test shortcuts.')
    screenshot_files = sorted((report / 'installed-screenshots').glob('*.png'))
    if not screenshot_files:
        raise RuntimeError('Rendered installed game did not produce screenshots.')
    result = dict(passed=True, checked_at=datetime.now(timezone.utc).isoformat(), version=record['version'],
                  pack_sha256=record['game_pack_sha256'], artifacts=record['artifacts'],
                  payload_files_verified=record['payload_files'], unicode_paths=True,
                  windows_uninstall_registration=installed_registration, shortcuts_verified=3,
                  uninstall_verified=True, real_player_saves_unchanged=True,
                  isolated_installation=True, existing_installation_unchanged=True,
                  checks=checks, screenshots=[dict(name=p.relative_to(report).as_posix(), sha256=digest(p)) for p in screenshot_files],
                  full_game_regression_repeated=False, installer_visual_review=False)
    write_json(report / 'verification.json', result)
    record['installation_verified'] = True
    record['installation_verification'] = str((report / 'verification.json').relative_to(ROOT))
    write_json(directory / 'distribution_manifest.json', record)
    # Delete only the extracted whitelist; preserve unexpected files for inspection.
    for name in [*record['payload'], 'SHA256SUMS.txt']:
        (portable_game / name).unlink()
    for folder in sorted((p for p in portable_game.rglob('*') if p.is_dir()), key=lambda p: len(p.parts), reverse=True):
        folder.rmdir()
    portable_game.rmdir()
    portable.rmdir()
    print(json.dumps({'passed': True, 'report': str(report / 'verification.json')}, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', default='Release/Distributions/0.7.3-rc1')
    parser.add_argument('--report', default='docs/size_optimization_20261018/distribution')
    args = parser.parse_args()
    verify((ROOT / args.directory).resolve(), (ROOT / args.report).resolve())
