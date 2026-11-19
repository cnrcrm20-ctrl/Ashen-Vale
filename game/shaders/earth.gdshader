shader_type spatial;
render_mode cull_disabled;
uniform float district;
uniform sampler2D loam : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D flags : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D soil_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D flags_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D soil_orm : repeat_enable, filter_linear_mipmap;
uniform sampler2D flags_orm : repeat_enable, filter_linear_mipmap;
varying vec3 place;
void vertex(){ place=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 p=place.xz;
 float center=sin(-p.y*.022+district*.77)*10.+sin(-p.y*.05+district)*2.6;
 float road=1.-smoothstep(2.1,4.7,abs(p.x-center)+.32*sin(p.y*.7));
 if(district==2.) road*=smoothstep(24.,58.,-p.y);
 vec2 a=p*.261, b=p*.38;
 float patch=.5+.27*sin(p.x*.18+p.y*.11)+.17*cos(p.x*.09-p.y*.17);
 vec3 moss=mix(vec3(.46,.55,.36),vec3(.67,.62,.53),patch);
 ALBEDO=mix(texture(loam,a).rgb*moss,texture(flags,b).rgb*vec3(.66,.64,.59),road);
 NORMAL_MAP=mix(texture(soil_normal,a).rgb,texture(flags_normal,b).rgb,road);
 vec3 orm=mix(texture(soil_orm,a).rgb,texture(flags_orm,b).rgb,road);
 NORMAL_MAP_DEPTH=.45; SPECULAR=.19; AO=orm.r; ROUGHNESS=mix(max(.35,orm.g),max(.30,orm.g*.74),road);
}
