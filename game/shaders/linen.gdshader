shader_type spatial;
render_mode cull_disabled;
uniform vec4 dye:source_color=vec4(.55,.25,.17,1.);
varying float stripe;
void vertex(){vec3 w=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; VERTEX.y+=.08*sin(w.z*1.9+TIME*1.5)*sin(UV.x*3.14159);stripe=UV.x;}
void fragment(){float seam=smoothstep(.87,.92,fract(stripe*9.));ALBEDO=mix(dye.rgb,dye.rgb*1.32+.035,seam*.6);ROUGHNESS=.94;}
