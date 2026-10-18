"""Publish only locally verified player artifacts to this project's GitHub Release."""
import argparse
import hashlib
import json
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from package_game import ROOT, digest, write_json
from publish_repository import REPOSITORY, api, github_token, upload_asset


def upload_with_curl(release, file):
    current = api('/repos/' + REPOSITORY + '/releases/' + str(release['id']))
    if not current['draft']:
        raise RuntimeError('Streaming uploads may only modify the current draft.')
    existing = next((item for item in current['assets'] if item['name'] == file.name), None)
    if existing and existing['state'] == 'uploaded':
        if existing['size'] != file.stat().st_size or existing.get('digest') != 'sha256:' + digest(file):
            raise RuntimeError('Completed draft asset differs: ' + file.name)
        return existing
    if existing:
        api('/repos/' + REPOSITORY + '/releases/assets/' + str(existing['id']), method='DELETE')
    url = current['upload_url'].split('{')[0] + '?name=' + urllib.parse.quote(file.name)
    command = ['curl.exe', '--silent', '--show-error', '--fail-with-body', '--request', 'POST',
               '--upload-file', str(file), '--connect-timeout', '30', '--max-time', '900',
               '--speed-limit', '16384', '--speed-time', '60', '--config', '-', url]
    proxy = urllib.request.getproxies().get('https')
    if proxy:
        command += ['--proxy', proxy]
    token = github_token().replace('\\', '\\\\').replace('"', '\\"')
    # Credentials go through stdin, never shell arguments, a file, or diagnostics.
    config = ('header = "Authorization: Bearer ' + token + '"\n'
              'header = "Content-Type: application/octet-stream"\n'
              'header = "User-Agent: DongBeiKangLian-distribution"\n')
    print(json.dumps(dict(streaming_upload=file.name, bytes=file.stat().st_size)), flush=True)
    result = subprocess.run(command, input=config, text=True, encoding='utf-8', capture_output=True, timeout=930)
    if result.returncode:
        raise RuntimeError('Streaming upload failed for ' + file.name + ': ' + result.stderr.strip())
    return json.loads(result.stdout)


def publish(directory, report, curl_upload=False):
    manifest = json.loads((directory / 'distribution_manifest.json').read_text(encoding='utf-8'))
    verification = json.loads((ROOT / manifest['installation_verification']).read_text(encoding='utf-8'))
    if not manifest.get('installation_verified') or not verification.get('passed') or verification['artifacts'] != manifest['artifacts']:
        raise RuntimeError('Complete local distribution verification before publishing.')
    files = [directory / item['name'] for item in manifest['artifacts']] + [directory / 'SHA256SUMS.txt']
    for item in manifest['artifacts']:
        if digest(directory / item['name']) != item['sha256']:
            raise RuntimeError('Artifact differs from the verified version: ' + item['name'])
    version = manifest['version']
    tag = 'v' + version
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    body = ('**东北抗联 烽火回声**，东北抗联题材原创单人剧情FPS。1938年深秋，从青岚林场夺回名册、营救战友，'
            '再经双人顺流渡河和密林土路进入松岭屯，完成三段穿院战斗。\n\n'
            '### 下载与游玩\n\n'
            '- **安装版**：下载 `Setup-Windows-x64.exe`，按中文向导安装，从开始菜单启动。支持卸载，保留用户存档。\n'
            '- **免安装版**：下载 `Portable-Windows-x64.zip`，完整解压后运行 `FenghuoEcho.exe`。两种版本任选其一。\n'
            '- 无需安装Godot、Python或Blender。Windows x64、键盘鼠标、支持OpenGL 3.3的显卡。首次启动等待场景准备。\n'
            '- 随附 `README.md` / `README.txt` 介绍剧情、人物、路线、操作和特色；`SHA256SUMS.txt` 用于核对下载。\n\n'
            '### 本版内容\n\n'
            '12组大院与窄街穿院、蹲伏和左右探头、三档画质、树林分块与院落合批、实际压弹动画，'
            '并包含最新入村路面接缝修复与跑步镜头晃动。\n\n'
            '本版无损合并重复环境贴图，排除未使用的整村展示模型，保留完整关卡、原贴图分辨率与音频。'
            '安装版及免安装ZIP均小于1 GB（1,000,000,000字节），使用同一份已验证游戏本体。\n\n'
            '### 验证与限制\n\n'
            '本批逐文件核对压缩包和安装内容，实际验证中文路径解压/安装、便携包108项基础检查、'
            '安装版有画面枪械与镜头检查、开始菜单入口和卸载；用户存档未改变。'
            '资源加载、贴图一致性、首关、院落、渡河、开场、导航与有画面画质/地图专项重新验证；'
            '本批没有重跑全量游戏回归，运行中的旧版游戏使帧率对比不具备受控条件。\n\n'
            '当前为试玩候选版：部分对白只有字幕，声音听审、连续美术/表演和真人难度仍待收尾；'
            '此前渡口短暂停顿未确认消除，最低配置及其他平台未验收。安装包尚未代码签名。'
            '来源与许可随包保留，公开下载不等于所有素材可自由再授权。')
    path = '/repos/' + REPOSITORY + '/releases'
    try:
        release = api(path + '/tags/' + tag)
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        release = next((r for r in api(path + '?per_page=100&check=' + str(time.time_ns())) if r['tag_name'] == tag), None)
        if release is None:
            release = api(path, method='POST', data=dict(tag_name=tag, target_commitish=commit,
                          name='东北抗联 烽火回声 ' + version + ' · 1 GB以内 Windows版', body=body,
                          draft=True, prerelease=True))
    if release['draft']:
        release = api(path + '/' + str(release['id']), method='PATCH',
                      data=dict(tag_name=tag, name='东北抗联 烽火回声 ' + version + ' · 1 GB以内 Windows版',
                                body=body, target_commitish=commit))
        if release['tag_name'] != tag:
            raise RuntimeError('Draft release tag changed unexpectedly; inspect it before uploading.')
        print(json.dumps(dict(draft_id=release['id'], tag=release['tag_name'])), flush=True)
        for file in files:
            expected = 'sha256:' + digest(file)
            existing = next((a for a in release.get('assets', []) if a['name'] == file.name), None)
            if existing and existing.get('state') == 'uploaded' and (existing.get('digest') != expected or existing['size'] != file.stat().st_size):
                raise RuntimeError('A different completed draft asset already uses this name: ' + file.name)
            asset = upload_with_curl(release, file) if curl_upload else upload_asset(release, file)
            if asset['size'] != file.stat().st_size or asset.get('digest') != expected:
                raise RuntimeError('GitHub upload digest does not match local artifact: ' + file.name)
            print(json.dumps(dict(uploaded=file.name, bytes=asset['size'], sha256=expected)), flush=True)
        release = api(path + '/' + str(release['id']), method='PATCH', data=dict(tag_name=tag, body=body, draft=False))
    else:
        # A retry after publication may verify downloads, but never replaces public bytes.
        for file in files:
            asset = next((a for a in release['assets'] if a['name'] == file.name), None)
            if not asset or asset['size'] != file.stat().st_size or asset.get('digest') != 'sha256:' + digest(file):
                raise RuntimeError('Published assets differ. Use a new version rather than replacing public files.')
    # Confirm the public guide and checksum download, in addition to server digests.
    downloaded = []
    for name in ['README.md', 'SHA256SUMS.txt']:
        asset = next(a for a in release['assets'] if a['name'] == name)
        with urllib.request.urlopen(asset['browser_download_url'], timeout=60) as response:
            remote_digest = hashlib.sha256(response.read()).hexdigest()
        if remote_digest != digest(directory / name):
            raise RuntimeError('Public download mismatch: ' + name)
        downloaded.append(name)
    result = dict(passed=True, url=release['html_url'], tag=tag, target_commit=release['target_commitish'],
                  public_downloads_verified=downloaded,
                  assets=[dict(name=a['name'], bytes=a['size'], digest=a.get('digest'), url=a['browser_download_url']) for a in release['assets']])
    write_json(report / 'github-release.json', result)
    print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', default='Release/Distributions/0.7.3-rc1')
    parser.add_argument('--report', default='docs/size_optimization_20261018/distribution')
    parser.add_argument('--curl-upload', action='store_true', help='Stream through curl when the local TLS proxy interrupts Python uploads.')
    args = parser.parse_args()
    publish((ROOT / args.directory).resolve(), (ROOT / args.report).resolve(), args.curl_upload)
