"""Inspect Blender DNA data blocks as bytes. Never starts Blender or runs scripts."""
import json
from pathlib import Path
import re
import struct

def inspect(path):
 raw=path.read_bytes()
 if raw[:7]!=b'BLENDER':raise ValueError('Unsupported/compressed Blender header')
 pointer=8 if raw[7:8]==b'-' else 4
 endian='<' if raw[8:9]==b'v' else '>'
 u32=lambda b,p:struct.unpack_from(endian+'I',b,p)[0]
 u16=lambda b,p:struct.unpack_from(endian+'H',b,p)[0]
 blocks=[];pos=12
 while pos+16+pointer<=len(raw):
  code=raw[pos:pos+4].rstrip(b'\x00').decode('ascii',errors='replace');size=u32(raw,pos+4)
  dna=u32(raw,pos+8+pointer);count=u32(raw,pos+12+pointer)
  payload=raw[pos+16+pointer:pos+16+pointer+size]
  blocks.append((code,dna,count,payload));pos+=16+pointer+size
  if code=='ENDB':break
 data=next(b[3] for b in blocks if b[0]=='DNA1');p=8
 names_count=u32(data,p);p+=4;names=[]
 for _ in range(names_count):
  end=data.index(0,p);names.append(data[p:end].decode());p=end+1
 p=(p+3)//4*4
 assert data[p:p+4]==b'TYPE';p+=4;ntypes=u32(data,p);p+=4;types=[]
 for _ in range(ntypes):
  end=data.index(0,p);types.append(data[p:end].decode());p=end+1
 p=(p+3)//4*4;assert data[p:p+4]==b'TLEN';p+=4
 lengths=[u16(data,p+i*2) for i in range(ntypes)];p+=ntypes*2;p=(p+3)//4*4
 assert data[p:p+4]==b'STRC';p+=4;nstruct=u32(data,p);p+=4;structs=[]
 for _ in range(nstruct):
  ti=u16(data,p);fields=u16(data,p+2);p+=4;offset=0;layout=[]
  for _ in range(fields):
   fti=u16(data,p);ni=u16(data,p+2);p+=4;name=names[ni]
   mult=1
   for v in re.findall(r'\[(\d+)\]',name):mult*=int(v)
   size=(pointer if '*' in name else lengths[fti])*mult
   layout.append((name,types[fti],offset,size));offset+=size
  structs.append((types[ti],lengths[ti],layout,offset))
 layouts={s[0]:s for s in structs}
 def get_name(payload):
  n=next((f for f in layouts['ID'][2] if f[0].startswith('name[')),None)
  return payload[n[2]:n[2]+n[3]].split(b'\0')[0].decode(errors='replace') if n else ''
 meshes=[];actions=[]
 for code,dna,count,data in blocks:
  if dna>=len(structs):continue
  name,size,fields,computed=structs[dna]
  if name=='Mesh':
   m={'name':get_name(data),'structure_bytes':size,'computed_structure_bytes':computed}
   for fn,ft,off,fs in fields:
    if fn in ['totvert','totface','totpoly','totedge','totloop','verts_num','faces_num','edges_num','corners_num'] and fs==4:
     m[fn]=u32(data,off)
   meshes.append(m)
  if name=='bAction':actions.append(get_name(data))
 return {'path':str(path),'version':raw[9:12].decode(),'pointer_bytes':pointer,'meshes':meshes,'actions':actions,'method':'Blender DNA byte parsing only; no asset execution or rendering.'}

root=Path(__file__).resolve().parent
rows=[inspect(p) for p in (root/'supplement').rglob('*.blend')]
(root/'blend_metadata.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
for row in rows:
 print(Path(row['path']).name,'meshes',len(row['meshes']),'actions',row['actions'])
 for m in row['meshes']:print(m)
