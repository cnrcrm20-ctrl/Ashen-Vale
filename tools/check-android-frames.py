"""Release QA: changing app states must be visible to the player, not just to logcat."""
from pathlib import Path
from PIL import Image,ImageStat,ImageChops
import sys
base=Path(sys.argv[1]);captured={}
for name in ['title','court','dialogue','resumed']:
 image=Image.open(base/('android-'+name+'.png')).convert('RGB');assert image.width>image.height
 image=image.resize((160,90));contrast=sum(ImageStat.Stat(image).stddev)/3; entropy=image.convert('L').entropy()
 print(name,'contrast',round(contrast,1),'entropy',round(entropy,2));assert contrast>14 and entropy>3,'blank Android frame: '+name
 captured[name]=image
for one,two in [('title','court'),('court','dialogue')]:
 delta=sum(ImageStat.Stat(ImageChops.difference(captured[one],captured[two])).mean)/3
 print(one,two,'mean color change',round(delta,1));assert delta>7,'frozen Android frame: '+one+', '+two
print('ANDROID_FRAMES PASS')
