from pathlib import Path
import json,array,math,subprocess,wave,hashlib
ROOT=Path(r'C:\GameMake\AssetLibrary\audio'); GAME=Path(r'C:\GameMake\GodotProject\assets\audio');GAME.mkdir(parents=True,exist_ok=True)
ready=json.loads((ROOT/'ready_to_import.json').read_text(encoding='utf-8'));idx=json.loads((ROOT/'audio_validation.json').read_text(encoding='utf-8'));manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
def decode(p):
 raw=subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(p),'-f','f32le','-ar','48000','-ac','1','-'],capture_output=True,check=True).stdout
 a=array.array('f');a.frombytes(raw);return a
def peak_adjust(a,db):
 peak=max(abs(v)for v in a);factor=10**(db/20)/max(peak,1e-8)
 return array.array('f',(v*factor for v in a))
def loop_crossfade(a,seconds):
 n=int(seconds*48000);tail=a[-n:];head=a[:n]
 blend=array.array('f',(tail[i]*(1-i/(n-1))+head[i]*(i/(n-1))for i in range(n)))
 return a[n:-n]+blend
records=[]
def save(name,a,sources,note,loop=False):
 p=GAME/name;pcm=array.array('h',(max(-32767,min(32767,round(v*32767)))for v in a))
 with wave.open(str(p),'wb')as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(48000);w.writeframes(pcm.tobytes())
 rms=(sum(v*v for v in a)/len(a))**.5
 rec={'game_path':str(p),'res_path':'res://assets/audio/'+name,'sources':sources,'modifications':note,'license':'CC0-1.0' if name.startswith('rifle') else 'CC-BY-3.0','sample_rate':48000,'channels':1,'duration_seconds':len(a)/48000,'frames':len(a),'peak_dbfs':round(20*math.log10(max(abs(v)for v in a)),2),'rms_dbfs':round(20*math.log10(max(rms,1e-12)),2),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'loop':loop}
 if loop:rec['loop_boundary_sample_difference']=abs(int(pcm[-1])-int(pcm[0]))
 subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(p),'-f','null','-'],capture_output=True,check=True);rec['decode_ok']=True;records.append(rec)
rifle=next(x for x in ready if x['path'].endswith('arisaka_near_01.wav'))
a=peak_adjust(decode(ROOT/rifle['path']),-6);save('rifle_arisaka_01.wav',a,[rifle['source_path']],'Single shot E_25P.wav from 0.513917s to 3.063917s; 48kHz mono PCM16, 80ms tail fade, peak -6dBFS. Source labels Arisaka .30-06; tonal reference, not verified original 6.5/7.7mm service ammunition.')
step=next(x for x in ready if x['path'].endswith('step_grass_01.wav'))
a=peak_adjust(decode(ROOT/step['path']),-14)
# Short edge fades eliminate abrupt nonzero event boundaries.
for i in range(min(240,len(a)//2)):
 a[i]*=i/240;a[-1-i]*=i/240
save('step_grass_01.wav',a,[step['source_path']],'Grass/dirt footstep derived by congusbongus from swuing. 48kHz mono PCM16, peak -14dBFS, 5ms edge fades.')
forest=next(x for x in idx if x['path'].endswith('amb_forest.flac'));wind=next(x for x in idx if x['path'].endswith('amb_wind_1.flac'))
f=decode(ROOT/forest['path']);w=loop_crossfade(decode(ROOT/wind['path']),.4)
frms=(sum(v*v for v in f)/len(f))**.5;wrms=(sum(v*v for v in w)/len(w))**.5
mix=array.array('f',(v/max(frms,1e-8)*.72+w[i%len(w)]/max(wrms,1e-8)*.28 for i,v in enumerate(f)))
a=loop_crossfade(mix,.6);rms=(sum(v*v for v in a)/len(a))**.5;factor=min(10**(-28/20)/rms,10**(-12/20)/max(abs(v)for v in a));a=array.array('f',(v*factor for v in a))
for i in range(96):
 gain=.5-.5*math.cos(math.pi*i/95);a[i]*=gain;a[-1-i]*=gain
save('forest_wind_loop.wav',a,[forest['path'],wind['path']],'Blender Foundation / Yo Frankie forest and wind blended 72:28 after RMS balancing. Wind wraps with 400ms crossfade; final ambience loop with 600ms crossfade and 2ms cosine seam fades to exact zero endpoints. 48kHz mono PCM16, RMS approximately -28dBFS, peak capped at -12dBFS.',True)
manifest['game_integration']=records
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8');(ROOT/'game_integration.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
(GAME/'CREDITS.md').write_text('''# Imported audio credits\n\n- `rifle_arisaka_01.wav`: The Free Firearm Sound Library, Ben Jaszczak, Brian Nelson, Kevin Heras and Matthew Nanney. CC0 1.0. https://opengameart.org/content/the-free-firearm-sound-library ; https://creativecommons.org/publicdomain/zero/1.0/ . Modified: one-shot crop, mono/48kHz conversion, tail fade, gain. Source metadata labels this Arisaka .30-06, not verified original Japanese service ammunition.\n- `step_grass_01.wav`: swuing, footstep-grass.wav https://freesound.org/people/swuing/sounds/38874/ ; prepared by congusbongus in https://opengameart.org/content/footsteps-on-different-surfaces . CC BY 3.0 https://creativecommons.org/licenses/by/3.0/ . Modified: resampled to mono/48kHz, gain, edge fades.\n- `forest_wind_loop.wav`: Blender Foundation, Yo Frankie! https://opengameart.org/content/ambient-mountain-river-wind-and-forest-and-waterfall . CC BY 3.0 https://creativecommons.org/licenses/by/3.0/ . Modified: forest/wind mix, resampling, mono conversion, crossfades for loop continuity, gain.\n\nOriginal archives, source pages, source license files, download URLs and SHA-256 hashes are preserved in `AssetLibrary/audio/manifest.json`; exact edits and audio measurements in `AssetLibrary/audio/game_integration.json`.\n''',encoding='utf-8')
print(json.dumps(records,ensure_ascii=True,indent=2))
