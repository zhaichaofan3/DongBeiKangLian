"""Authenticated GitHub operations; credentials never leave this process."""
import argparse
import base64
import hashlib
import http.client
import json
import subprocess
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

REPOSITORY = "zhaichaofan3/DongBeiKangLian"
ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'docs/maintenance/repository-20261016'
TAG = 'v0.7.0-rc1'


def github_token():
    result = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
                            text=True, capture_output=True, check=True)
    fields = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    return fields["password"]


def api(path, method="GET", data=None):
    body = json.dumps(data).encode() if data is not None else None
    request = urllib.request.Request("https://api.github.com" + path, data=body, method=method,
        headers={"Authorization": "Bearer " + github_token(), "User-Agent": "DongBeiKangLian-maintenance",
                 "Accept": "application/vnd.github+json", "Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=60) as response:
        body = response.read()
        return json.loads(body) if body else None


def inspect():
    repository = api("/repos/" + REPOSITORY)
    user = api("/user")
    print(json.dumps({"repository": repository["full_name"], "private": repository["private"],
        "default_branch": repository["default_branch"], "size_KiB": repository["size"],
        "authenticated_as": user["login"], "user_id": user["id"],
        "can_push": repository.get("permissions", {}).get("push", False)}, ensure_ascii=False))


def verify_remote():
    local = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    remote = api('/repos/' + REPOSITORY + '/commits/main')
    repository = api('/repos/' + REPOSITORY)
    result = dict(url=repository['html_url'], private=repository['private'], branch='main',
                  local_commit=local, remote_commit=remote['sha'], matched=local == remote['sha'])
    (REPORT / 'remote-repository.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result), flush=True)
    if not result['matched']:
        raise RuntimeError('Remote main does not match the current local commit')


def verify_release():
    item = api('/repos/' + REPOSITORY + '/releases/tags/' + TAG)
    record = json.loads((REPORT / 'release-archive.json').read_text())
    archive = next(asset for asset in item['assets'] if asset['name'].endswith('.zip'))
    checksum = next(asset for asset in item['assets'] if asset['name'].endswith('.sha256'))
    assert not item['draft'] and archive['size'] == record['bytes']
    assert archive['digest'] == 'sha256:' + record['sha256']
    with urllib.request.urlopen(checksum['browser_download_url'], timeout=60) as response:
        remote_checksum = response.read(4096).decode('ascii').split()[0]
    assert remote_checksum == record['sha256']
    result = dict(url=item['html_url'], tag=TAG, published=True, prerelease=item['prerelease'],
                  checksum_download_verified=True,
                  assets=[dict(name=asset['name'], bytes=asset['size'], url=asset['browser_download_url'], digest=asset.get('digest')) for asset in item['assets']])
    (REPORT / 'github-release.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result), flush=True)


def lfs_status():
    files = json.loads(subprocess.check_output(['git', 'lfs', 'ls-files', '--json'], cwd=ROOT, text=True, encoding='utf-8'))['files']
    ordered = sorted(files, key=lambda item: item['size'], reverse=True)
    selected = ordered[:3] + ordered[-3:]
    body = json.dumps(dict(operation='download', transfers=['basic'], objects=[dict(oid=item['oid'], size=item['size']) for item in selected])).encode()
    auth = base64.b64encode(('zhaichaofan3:' + github_token()).encode()).decode()
    request = urllib.request.Request('https://github.com/' + REPOSITORY + '.git/info/lfs/objects/batch', data=body,
        headers={'Authorization': 'Basic ' + auth, 'Content-Type': 'application/vnd.git-lfs+json',
                 'Accept': 'application/vnd.git-lfs+json', 'User-Agent': 'DongBeiKangLian-maintenance'})
    with urllib.request.urlopen(request, timeout=60) as response:
        result = json.load(response)
    print(json.dumps(dict(samples=[dict(oid=item['oid'][:12], exists='download' in item.get('actions', {}), error=item.get('error')) for item in result['objects']]), ensure_ascii=False))


def lfs_inventory():
    files = json.loads(subprocess.check_output(['git', 'lfs', 'ls-files', '--json'], cwd=ROOT, text=True, encoding='utf-8'))['files']
    unique = {item['oid']: dict(oid=item['oid'], size=item['size']) for item in files}
    objects = list(unique.values())
    token = github_token()
    auth = base64.b64encode(('zhaichaofan3:' + token).encode()).decode()
    uploaded = []
    for start in range(0, len(objects), 100):
        request = urllib.request.Request('https://github.com/' + REPOSITORY + '.git/info/lfs/objects/batch',
            data=json.dumps(dict(operation='download', transfers=['basic'], objects=objects[start:start+100])).encode(),
            headers={'Authorization': 'Basic ' + auth, 'Content-Type': 'application/vnd.git-lfs+json',
                     'Accept': 'application/vnd.git-lfs+json', 'User-Agent': 'DongBeiKangLian-maintenance'})
        with urllib.request.urlopen(request, timeout=60) as response:
            batch = json.load(response)
        uploaded.extend(item for item in batch['objects'] if 'download' in item.get('actions', {}))
        print(json.dumps(dict(objects_checked=min(start+100, len(objects)), uploaded_objects=len(uploaded),
                              uploaded_MiB=sum(item['size'] for item in uploaded)//1024**2)), flush=True)
    result = dict(unique_objects=len(objects), total_bytes=sum(item['size'] for item in objects),
                  uploaded_objects=len(uploaded), uploaded_bytes=sum(item['size'] for item in uploaded))
    (REPORT / 'remote-lfs-validation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result), flush=True)


def package():
    output = ROOT / '.publish'
    output.mkdir(exist_ok=True)
    archive = output / 'FenghuoEcho-0.7.0-rc1-Windows-x64.zip'
    selected = [source for source in sorted((ROOT / 'Release').rglob('*'))
                if source.is_file() and 'Validation' not in source.relative_to(ROOT / 'Release').parts
                and source.name != 'SHA256SUMS.txt']
    sums = []
    for source in selected:
        with source.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        sums.append(digest + '  ' + source.relative_to(ROOT / 'Release').as_posix())
    manifest = ROOT / 'Release/SHA256SUMS.txt'
    manifest.write_text('\n'.join(sums) + '\n', encoding='utf-8')
    selected.append(manifest)
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=3, allowZip64=True) as target:
        for source in selected:
            target.write(source, Path('FenghuoEcho') / source.relative_to(ROOT / 'Release'))
    with archive.open('rb') as source:
        digest = hashlib.file_digest(source, 'sha256').hexdigest()
    checksum = output / (archive.name + '.sha256')
    checksum.write_text(digest + '  ' + archive.name + '\n', encoding='ascii')
    result = dict(path=archive.relative_to(ROOT).as_posix(), bytes=archive.stat().st_size, sha256=digest)
    (REPORT / 'release-archive.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result), flush=True)


def verify_package():
    record = json.loads((REPORT / 'release-archive.json').read_text())
    archive = ROOT / record['path']
    with archive.open('rb') as source:
        assert hashlib.file_digest(source, 'sha256').hexdigest() == record['sha256']
    with zipfile.ZipFile(archive) as package_file:
        manifest = package_file.read('FenghuoEcho/SHA256SUMS.txt').decode('utf-8')
        expected = dict((name, digest) for digest, name in (line.split('  ', 1) for line in manifest.splitlines()))
        for name, digest in expected.items():
            with package_file.open('FenghuoEcho/' + name) as source:
                assert hashlib.file_digest(source, 'sha256').hexdigest() == digest, name
        names = package_file.namelist()
        assert len(names) == len(expected) + 1
        assert not any('/Validation/' in name for name in names)
    result = dict(archive=archive.name, files_verified=len(expected), archive_sha256=record['sha256'], passed=True)
    (REPORT / 'package-validation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result), flush=True)


def upload_asset(release, path):
    existing = next((item for item in release.get('assets', []) if item['name'] == path.name), None)
    if existing and existing.get('state') == 'uploaded' and existing['size'] == path.stat().st_size:
        return existing
    if existing:
        api('/repos/' + REPOSITORY + '/releases/assets/' + str(existing['id']), method='DELETE')
    url = urllib.parse.urlsplit(release['upload_url'].split('{')[0] + '?name=' + urllib.parse.quote(path.name))
    proxy = urllib.request.getproxies().get('https')
    if proxy:
        endpoint = urllib.parse.urlsplit(proxy if '://' in proxy else 'http://' + proxy)
        connection = http.client.HTTPSConnection(endpoint.hostname, endpoint.port, timeout=180)
        connection.set_tunnel(url.hostname, 443)
    else:
        connection = http.client.HTTPSConnection(url.hostname, timeout=180)
    try:
        connection.putrequest('POST', url.path + '?' + url.query)
        connection.putheader('Authorization', 'Bearer ' + github_token())
        connection.putheader('User-Agent', 'DongBeiKangLian-maintenance')
        connection.putheader('Content-Type', 'application/octet-stream')
        connection.putheader('Content-Length', str(path.stat().st_size))
        connection.endheaders()
        sent, reported = 0, 0
        with path.open('rb') as source:
            while chunk := source.read(8 * 1024**2):
                connection.send(chunk)
                sent += len(chunk)
                if sent - reported >= 64 * 1024**2:
                    print(json.dumps(dict(upload=path.name, MiB_sent=sent // 1024**2)), flush=True)
                    reported = sent
        response = connection.getresponse()
        body = response.read()
        if response.status != 201:
            raise RuntimeError('Release asset upload failed: HTTP ' + str(response.status))
        return json.loads(body)
    finally:
        connection.close()


def release():
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    try:
        item = api('/repos/' + REPOSITORY + '/releases/tags/' + TAG)
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        drafts = api('/repos/' + REPOSITORY + '/releases')
        item = next((candidate for candidate in drafts if candidate['tag_name'] == TAG), None)
        if item is None:
            item = api('/repos/' + REPOSITORY + '/releases', method='POST', data=dict(
            tag_name=TAG, target_commitish=commit, name='0.7.0-rc1 · 林海归途试玩候选版',
            draft=True, prerelease=True,
            body='Windows离线试玩候选版。双人渡河、密林入村与完整松岭屯三段战斗。\n\n'
                 '解压Windows-x64.zip后运行FenghuoEcho.exe，保留同目录全部文件。\n\n'
                 '新增部分对白仍为字幕，声音听审、连续美术与真人难度尚待验收。来源和许可随包提供。'))
    files = sorted((ROOT / '.publish').glob('*.zip*'))
    if len(files) != 2:
        raise RuntimeError('Run package first; expected one ZIP and its SHA-256 file')
    assets = [upload_asset(item, path) for path in files]
    for path, asset in zip(files, assets):
        with path.open('rb') as source:
            expected = 'sha256:' + hashlib.file_digest(source, 'sha256').hexdigest()
        if asset['size'] != path.stat().st_size or (asset.get('digest') and asset['digest'] != expected):
            raise RuntimeError('Uploaded release asset does not match local bytes: ' + path.name)
    item = api('/repos/' + REPOSITORY + '/releases/' + str(item['id']), method='PATCH', data=dict(draft=False))
    assets = item['assets']
    result = dict(url=item['html_url'], tag=TAG, target_commit=commit,
                  assets=[dict(name=a['name'], bytes=a['size'], url=a['browser_download_url'], digest=a.get('digest')) for a in assets])
    (REPORT / 'github-release.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["inspect", "verify_remote", "verify_release", "lfs_status", "lfs_inventory", "package", "verify_package", "release"])
    args = parser.parse_args()
    try:
        globals()[args.command]()
    except urllib.error.HTTPError as error:
        print(json.dumps({"error": "GitHub API request failed", "status": error.code}))
        raise SystemExit(1)
