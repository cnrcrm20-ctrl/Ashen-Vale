"""Compile the chapter's authoring sheet and the canonical novel to offline game data."""
from pathlib import Path
import json,re,sys
root=Path(__file__).resolve().parents[1]; data=root/'game/data'; data.mkdir(exist_ok=True)
book=(root/'episode-1.md').read_text(); prose,appendix=book.split('\n---\n',1)
zones=[]; beats=[]; current=None
for line in (root/'story/episode1.av').read_text().splitlines():
 line=line.strip()
 if not line or line.startswith('#'):continue
 if line.startswith('@'):
  n,sub=line[1:].split('|');zones.append({'name':n,'subtitle':sub})
 elif line.startswith(':'):
  loc,model,kind,title=line[1:].split('|');loc=[float(a) for a in loc.split(',')];current=dict(id=len(beats),zone=len(zones)-1,at=loc,model=model,kind=kind,title=title,lines=[],clues=[]);beats.append(current)
 elif line.startswith('?'):
  k,q,*options=line[1:].split('|');current['ask']={'correct':int(k),'q':q,'options':[a.split('~') for a in options]}
 elif line.startswith('+'):
  label,note=line[1:].split('|');current['clues'].append([label,note]);
 else:
  speaker,text=line.split('|',1);current['lines'].append([speaker,text]);
spells=[]
for l in appendix.splitlines():
 if re.match(r'^\| \d{2} \|',l):
  num,school,name,typ,desc=[a.strip().strip('*') for a in l.strip('|').split('|')];spells.append([int(num),school,name,typ,desc])
chapters=[{'title':x.split('\n',1)[0].strip(),'text':x.split('\n',1)[1].strip().replace('**','').replace('*','')} for x in prose.split('### ')[1:]]
assert len(zones)==len(chapters)==7 and len(spells)==34 and sum(s[3]=='Karanlık' for s in spells)==8 and len(set(s[1] for s in spells))==8
assert all(b['lines'] for b in beats) and all(len(b['clues'])==3 for b in beats if b['kind']=='search')
for b in beats:
 if 'ask' in b: assert all(len(a)==2 for a in b['ask']['options']) and -1<=b['ask']['correct']<len(b['ask']['options'])
for name,obj in [('chapter',{'zones':zones,'beats':beats}),('archive',{'chapters':chapters,'spells':spells})]:
 f=data/(name+'.json'); out=json.dumps(obj,ensure_ascii=False,indent=1)+'\n'
 if '--check' in sys.argv:assert f.read_text()==out,f'{f} is out of date'
 else:f.write_text(out)
print(f'{len(zones)} districts · {len(beats)} interactive beats · {sum(len(b["lines"]) for b in beats)} dialogue pages · 34 spells')
