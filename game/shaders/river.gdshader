shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep:source_color=vec3(.10,.39,.38);
uniform vec3 light_water:source_color=vec3(.38,.65,.57);
varying vec3 wp;
void vertex(){ wp=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; VERTEX.y+=.035*sin(wp.z*.8+TIME*1.4)+.018*sin(wp.x*1.2-TIME); }
void fragment(){float r=.5+.5*sin(wp.z*2.1+wp.x*.7+sin(wp.x*1.7+TIME)*1.3-TIME*1.85); ALBEDO=mix(deep,light_water,r*.45); EMISSION=vec3(.12,.13,.09)*smoothstep(.955,1.,r); ROUGHNESS=.26; METALLIC=.12;}
