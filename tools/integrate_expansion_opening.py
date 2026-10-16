"""Assign three existing wide shots to the playable village, preserving audio timing."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / 'GodotProject/assets/opening/opening.json'
data = json.loads(path.read_text(encoding='utf-8'))
updates = {
    'A-01': dict(title='林场与松岭屯', camera_from=[1238,60,324], camera_to=[1220,52,302], look_at=[1125,3,190], look_at_to=[1126,3,170], environment='songling_village'),
    'A-04': dict(title='青岚林场的屋舍与木料', camera_from=[75,30,108], camera_to=[70,26,99], look_at=[43,3,60], actors=[], environment='qinglan_logging'),
    'A-06': dict(title='沿原村道看见家园', camera_from=[1171,18,229], camera_to=[1161,16,210], look_at=[1138,2.8,179], actors=[], environment='songling_village'),
}
for shot in data['shots']:
    if shot['id'] in updates:
        shot.update(updates[shot['id']])
        shot['s07_placeholder'] = 'Original supplied settlement and logging camp, joined in the establishing sequence; fixed narration and timing retained.'
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('VILLAGE_ESTABLISHING_SHOTS', list(updates))
