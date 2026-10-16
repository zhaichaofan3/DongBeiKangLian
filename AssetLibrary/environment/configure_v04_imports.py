"""Give programmatically loaded PBR images explicit 3D import defaults."""
import hashlib
import json
from pathlib import Path
import re

project = Path(r'C:\GameMake\GodotProject')
asset_root = project / 'assets/environment'
template = (asset_root / 'textures/forest_ground_04/forest_ground_04_diff_2k.jpg.import').read_text(encoding='utf-8')
configured = []
for image in sorted(asset_root.rglob('*')):
    if image.suffix.lower() not in ('.jpg', '.png'):
        continue
    config_path = image.with_suffix(image.suffix + '.import')
    if config_path.exists():
        config = config_path.read_text(encoding='utf-8')
    else:
        resource = 'res://' + image.relative_to(project).as_posix()
        imported = 'res://.godot/imported/' + image.name + '-' + hashlib.md5(resource.encode()).hexdigest() + '.ctex'
        config = re.sub(r'^uid=.*\n', '', template, flags=re.M)
        config = re.sub(r'^path=.*$', 'path="' + imported + '"', config, flags=re.M)
        config = re.sub(r'^source_file=.*$', 'source_file="' + resource + '"', config, flags=re.M)
        config = re.sub(r'^dest_files=.*$', 'dest_files=["' + imported + '"]', config, flags=re.M)
    is_normal = '_nor_gl_' in image.name
    for key, value in {'compress/mode': '2', 'compress/normal_map': '1' if is_normal else '2',
                       'mipmaps/generate': 'true', 'detect_3d/compress_to': '0'}.items():
        config = re.sub('^' + re.escape(key) + '=.*$', key + '=' + value, config, flags=re.M)
    config_path.write_text(config, encoding='utf-8')
    configured.append({'path': image.relative_to(project).as_posix(), 'normal_map': is_normal, 'mipmaps': True})
(Path(r'C:\GameMake\docs') / 'v04_environment_texture_imports.json').write_text(json.dumps(configured, indent=2), encoding='utf-8')
manifest = json.loads((asset_root / 'sources.json').read_text(encoding='utf-8'))
for entry in manifest['assets']:
    for record in entry['files']:
        path = project / record['game_path']
        assert path.exists(), path
        assert path.stat().st_size == record['bytes'], path
        assert hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256'], path
print('Configured', len(configured), 'images; selected source integrity PASS')
