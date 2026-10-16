"""Read-only asset integrity and dependency checks; no content execution."""
import hashlib
import json
from pathlib import Path
from urllib.parse import unquote
from PIL import Image

root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
results=[]
for asset in manifest['assets']:
    report={'id':asset['id'],'type':asset['type'],'errors':[],'images':[], 'gltf':[]}
    for item in asset['files']:
        path=root/item['path']
        if not path.exists():
            report['errors'].append('Missing '+item['path']);continue
        raw=path.read_bytes()
        if len(raw)!=item.get('bytes') or hashlib.sha256(raw).hexdigest()!=item.get('sha256'):
            report['errors'].append('Integrity mismatch '+item['path'])
        if path.suffix.lower() in ('.jpg','.png'):
            try:
                with Image.open(path) as image:
                    resolution=image.size;image.verify()
                report['images'].append({'path':item['path'],'resolution':resolution})
            except Exception as e:
                report['errors'].append('Image decode '+str(e))
        elif path.suffix.lower()=='.gltf':
            try:
                doc=json.loads(raw)
                uris=[]
                for key in ('buffers','images'):
                    for dep in doc.get(key,[]):
                        uri=dep.get('uri')
                        if uri and not uri.startswith('data:'):
                            dependency=(path.parent/unquote(uri)).resolve()
                            if not dependency.is_relative_to(root.resolve()) or not dependency.is_file():
                                report['errors'].append('Missing/unsafe glTF dependency '+uri)
                            elif key=='buffers' and dependency.stat().st_size < dep['byteLength']:
                                report['errors'].append('Short glTF buffer '+uri)
                            uris.append(uri)
                report['gltf'].append({'path':item['path'],'version':doc.get('asset',{}).get('version'),
                    'meshes':len(doc.get('meshes',[])), 'materials':len(doc.get('materials',[])),
                    'external_dependencies':uris})
            except Exception as e:
                report['errors'].append('glTF parse '+str(e))
        elif path.suffix.lower()=='.hdr':
            if not raw.startswith((b'#?RADIANCE',b'#?RGBE')):
                report['errors'].append('Invalid Radiance header '+item['path'])
    results.append(report)
summary={'asset_count':len(results),'file_count':sum(len(a['files']) for a in manifest['assets']),
    'bytes':sum(f.get('bytes',0) for a in manifest['assets'] for f in a['files']),
    'errors':sum(len(a['errors']) for a in results), 'assets':results}
(root/'verification.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k!='assets'}))
for a in results:
    if a['errors']:print(a['id'],a['errors'])
if summary['errors']:raise SystemExit(1)
