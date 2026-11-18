"""Attach useful, bounded Godot diagnostics to the check itself, not only zipped logs."""
import glob, pathlib, re, subprocess, os, json, base64
entries={};seen=set()
def blob(b):
 return subprocess.check_output(['gh','api','repos/'+os.environ['GITHUB_REPOSITORY']+'/git/blobs','-X','POST','--input','-','--jq','.sha'],input=json.dumps({'encoding':'base64','content':base64.b64encode(b).decode()}).encode()).decode().strip()
for f in glob.glob('build/*.log')+glob.glob('build/device/*.log'):
 if pathlib.Path(f).name=='licenses.log':continue
 lines=pathlib.Path(f).read_text(errors='replace').splitlines();errors=[]
 for i,l in enumerate(lines):
  if any(x in l for x in ['ERROR:', 'Parse Error:', 'TEST:','SHADER ERROR:','CHAPTER_SMOKE','VISUAL_SMOKE','ANDROID_SMOKE','PACE_MODEL','AV_READY','Missing Android state','AV_BEAT 0','ANDROID_SMOKE']):
   msg=' '.join(lines[i:i+2])[:1000];
   if msg not in seen:errors.append(msg);seen.add(msg)
 print('::notice title='+pathlib.Path(f).name+'::'+(' | '.join(errors[:12]) if errors else ' '.join(lines[-4:]))[:6000].replace('%','%25').replace('\r','%0D'))
 entries[pathlib.Path(f).name]=blob(('\n'.join(errors[:50]+lines[-50:])).encode())
for f in glob.glob('build/shots/*.png'):entries[pathlib.Path(f).name]=blob(pathlib.Path(f).read_bytes())
ref=blob(json.dumps(entries).encode());open(os.environ['GITHUB_OUTPUT'],'a').write('ref='+ref+'\n')
