"""Transport *public* APK signatures, never a release key or a whole binary in Git.

make UNSIGNED SIGNED PATCH       -- local/offline only
apply UNSIGNED PATCH SIGNED      -- CI, exact hashes checked at both ends
The signer preserves compressed game data. Copy it from the validated CI artifact
by offset, store only headers, public signatures and changed bytes in the patch.
"""
from pathlib import Path
from hashlib import sha256
import argparse,base64,gzip,io,json,struct,zipfile

def digest(b):return sha256(b).hexdigest()
def payloads(b):
 with zipfile.ZipFile(io.BytesIO(b)) as z:
  for f in z.infolist():
   offset=f.header_offset
   name,extra=struct.unpack_from('<HH',b,offset+26)
   yield f.filename,offset+30+name+extra,f.compress_size

def make(a,b):
 source={name:(at,length) for name,at,length in payloads(a)};ops=[];end=0
 def literal(part):
  if part:ops.append(base64.b64encode(part).decode('ascii'))
 for name,at,n in sorted(payloads(b),key=lambda x:x[1]):
  i,size=source.get(name,(0,-1))
  if not n or n!=size or memoryview(a)[i:i+n]!=memoryview(b)[at:at+n]:continue
  literal(b[end:at]);ops.append([i,n]);end=at+n
 literal(b[end:]);return gzip.compress(json.dumps({'format':1,'base':digest(a),'apk':digest(b),'ops':ops},separators=(',',':')).encode(),mtime=0)

def apply(a,p):
 data=json.loads(gzip.decompress(p));assert data['format']==1 and digest(a)==data['base'],'wrong source artifact'
 out=io.BytesIO()
 for op in data['ops']:
  if isinstance(op,list):
   i,n=op;assert i>=0 and n>=0 and i+n<=len(a);out.write(a[i:i+n])
  else:out.write(base64.b64decode(op,validate=True))
 b=out.getvalue();assert digest(b)==data['apk'],'signed APK digest mismatch';return b

if __name__=='__main__':
 par=argparse.ArgumentParser(description=__doc__);par.add_argument('mode',choices=['make','apply']);par.add_argument('base',type=Path);par.add_argument('input',type=Path);par.add_argument('output',type=Path);args=par.parse_args()
 a=args.base.read_bytes();b=args.input.read_bytes()
 if args.mode=='make':
  result=make(a,b);assert apply(a,result)==b,'roundtrip';assert len(result)<2*1024*1024,'patch unexpectedly large; do not commit APKs'
 else:result=apply(a,b)
 args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(result);print(args.output.name,len(result),digest(result))
