"""Publish only locally verified player artifacts to this project's GitHub Release."""
import argparse
import hashlib
import json
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

from package_game import ROOT, digest, write_json
from publish_repository import REPOSITORY, api, upload_asset


def publish(directory, report):
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
    body = ('东北抗联题材原创单人剧情FPS。1938年深秋，从青岚林场夺回名册、营救战友，'
            '再经双人顺流渡河和密林土路进入松岭屯，完成三段穿院战斗。\n\n'
            '### 下载与游玩\n\n'
            '- **安装版**：下载 `Setup-Windows-x64.exe`，按中文向导安装，从开始菜单启动。支持卸载，保留用户存档。\n'
            '- **免安装版**：下载 `Portable-Windows-x64.zip`，完整解压后运行 `FenghuoEcho.exe`。两种版本任选其一。\n'
            '- 无需安装Godot、Python或Blender。Windows x64、键盘鼠标、支持OpenGL 3.3的显卡。首次启动等待场景准备。\n'
            '- 随附 `README.md` / `README.txt` 介绍剧情、人物、路线、操作和特色；`SHA256SUMS.txt` 用于核对下载。\n\n'
            '### 本版内容\n\n'
            '12组大院与窄街穿院、蹲伏和左右探头、三档画质、树林分块与院落合批、实际压弹动画，'
            '并包含最新入村路面接缝修复与跑步镜头晃动。安装和免安装包使用同一份已验证游戏本体。\n\n'
            '### 验证与限制\n\n'
            '本批逐文件核对压缩包和安装内容，实际验证中文路径解压/安装、便携包108项基础检查、'
            '安装版有画面枪械与镜头检查、开始菜单入口和卸载；用户存档未改变。'
            '游戏内容沿用2026-10-17专项验证，本批没有重跑全量游戏回归或性能基准。\n\n'
            '当前为试玩候选版：部分对白只有字幕，声音听审、连续美术/表演和真人难度仍待收尾；'
            '此前渡口短暂停顿未确认消除，最低配置及其他平台未验收。安装包尚未代码签名。'
            '来源与许可随包保留，公开下载不等于所有素材可自由再授权。')
    path = '/repos/' + REPOSITORY + '/releases'
    try:
        release = api(path + '/tags/' + tag)
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        release = next((r for r in api(path) if r['tag_name'] == tag), None)
        if release is None:
            release = api(path, method='POST', data=dict(tag_name=tag, target_commitish=commit,
                          name=version + ' · 林海归途 Windows安装版与免安装版', body=body,
                          draft=True, prerelease=True))
    if release['draft']:
        for file in files:
            expected = 'sha256:' + digest(file)
            existing = next((a for a in release.get('assets', []) if a['name'] == file.name), None)
            if existing and existing.get('state') == 'uploaded' and (existing.get('digest') != expected or existing['size'] != file.stat().st_size):
                raise RuntimeError('A different completed draft asset already uses this name: ' + file.name)
            asset = upload_asset(release, file)
            if asset['size'] != file.stat().st_size or asset.get('digest') != expected:
                raise RuntimeError('GitHub upload digest does not match local artifact: ' + file.name)
            print(json.dumps(dict(uploaded=file.name, bytes=asset['size'], sha256=expected)), flush=True)
        release = api(path + '/' + str(release['id']), method='PATCH', data=dict(body=body, draft=False))
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
    parser.add_argument('--directory', default='Release/Distributions/0.7.2-rc1')
    parser.add_argument('--report', default='docs/distribution_20261018')
    args = parser.parse_args()
    publish((ROOT / args.directory).resolve(), (ROOT / args.report).resolve())
