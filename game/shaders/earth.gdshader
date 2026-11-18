shader_type spatial;
render_mode cull_disabled;
uniform float district=0.;
varying vec3 place;
float h(vec2 p){return fract(sin(dot(p,vec2(27.13,91.73)))*4375.23);}
float grain(vec2 p){vec2 a=floor(p), f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(a),h(a+vec2(1,0)),f.x),mix(h(a+vec2(0,1)),h(a+1.),f.x),f.y);}
void vertex(){place=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){vec2 p=place.xz;float c=sin(-p.y*.022+district*.77)*10.+sin(-p.y*.05+district)*2.6;float path=(1.-smoothstep(2.7,4.7,abs(p.x-c)+grain(p*.6)*.6));vec2 q=vec2((p.x-c)*1.3,p.y*1.32);q.x+=mod(floor(q.y),2.)*.5+grain(p*.38)*.23;vec2 uv=abs(fract(q)-.5);float seam=smoothstep(.425,.497,max(uv.x,uv.y));float flag=(.91+.12*h(floor(q)))-seam*.19;float mottled=.9+.12*grain(p*.43)+.08*grain(p*3.);ALBEDO=COLOR.rgb*mix(mottled,flag*mottled,path*.9);ROUGHNESS=.92;}
