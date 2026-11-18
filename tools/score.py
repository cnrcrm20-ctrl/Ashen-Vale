"""Render the original offline score and interaction palette. NumPy + soundfile; assets ship in APK."""
import numpy as np,soundfile as sf
from pathlib import Path
P=Path(__file__).resolve().parents[1]/'game/audio';P.mkdir(exist_ok=True);sr=22050
rng=np.random.default_rng(1937)
def tone(note,dur,kind):
 t=np.arange(int(dur*sr))/sr;f=440*2**((note-69)/12);w=2*np.pi*f*t
 if kind=='lyre':return (np.sin(w)+.53*np.sin(2*w+.2)+.28*np.sin(3*w)+.13*np.sin(5*w))*np.exp(-t*2.8)*(1-np.exp(-t*90))
 return (np.sin(w+.12*np.sin(2*np.pi*4.7*t))+.2*np.sin(2*w))*(1-np.exp(-t*3))*np.minimum(1,(dur-t)*2)*(.8+.14*np.sin(t*5))
for num,name in enumerate(['kirecdam','vadi','olcu']):
 beat=[.69,.77,.64][num];length=beat*96;out=np.zeros((int(sr*length),2)); key=[50,53,55][num];mel=[0,7,10,9,5,3,0,2,7,5,3,2,0,5,7,3];
 def add(a,pos,pan,vol):
  for delay,v in [(0,1),(.16,.18),(.37,.11),(.68,.065)]:
   idx=(int(sr*(pos+delay))+np.arange(len(a)))%len(out);out[idx,0]+=a*(1-pan)*vol*v;out[idx,1]+=a*pan*vol*v
 for bar in range(16):
  base=key+[0,0,-5,-2,3,-5,-2,0][bar%8];start=bar*6*beat
  for j in [0,1.5,2.5,4,5.25]:add(tone(base+[0,7,12,7,10][[0,1.5,2.5,4,5.25].index(j)],2.6,'lyre'),start+j*beat,.45+.16*np.sin(bar+j),.20)
  if bar%2==0:
   add(tone(key+12+mel[bar],beat*3.5,'flute'),start+.8*beat,.59,.12);add(tone(key+12+mel[bar+1],beat*2.7,'flute'),start+4.3*beat,.61,.10)
  add(tone(base-12,beat*5.9,'drone'),start,.48,.105)
 sf.write(P/(name+'.ogg'),np.tanh(out*1.45),sr,format='OGG',subtype='VORBIS')
for name,notes,d in [('tap',[75],.16),('seal',[62,69,74],.8),('ember',[72,79,83],.65),('water',[71,66,74],1.0),('shield',[48,55,62],.44),('wind',[67,72,76],.48),('step',[36],.095),('miss',[45,43],.29)]:
 out=np.zeros(int(sr*(d+.3)))
 for i,n in enumerate(notes):
  a=tone(n,d,'lyre')*np.exp(-np.arange(int(d*sr))/sr*(5 if name!='step' else 24));start=int(.075*i*sr);out[start:start+len(a)]+=a*.28
 if name in ['step','wind','water']:out+=rng.normal(0,1,len(out))*.055*np.exp(-np.arange(len(out))/sr*(12 if name!='step' else 43))
 sf.write(P/(name+'.wav'),np.tanh(out),sr)
