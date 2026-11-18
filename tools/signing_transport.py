"""Stage the runner-built release for offline signing without trusting a runner with the release key.
No ref or release is created. Only immutable build content, size and digest leave the build job.
"""
import os, sys, json, base64, hashlib, subprocess, pathlib
def blob(data):
 return subprocess.check_output(['gh','api','repos/'+os.environ['GITHUB_REPOSITORY']+'/git/blobs','-X','POST','--input','-','--jq','.sha'],input=json.dumps({'encoding':'base64','content':base64.b64encode(data).decode()}).encode()).decode().strip()
p=pathlib.Path('build/android/Ashen-Vale-Episode-1.apk');b=p.read_bytes(); manifest={'sha256':hashlib.sha256(b).hexdigest(),'size':len(b),'commit':os.environ['GITHUB_SHA'],'chunks':[blob(b[i:i+4194304]) for i in range(0,len(b),4194304)]}; ref=blob(json.dumps(manifest).encode()); print('OFFLINE_SIGNING_MANIFEST='+ref);open(os.environ['GITHUB_OUTPUT'],'a').write('ref='+ref+'\n')
