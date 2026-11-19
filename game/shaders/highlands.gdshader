shader_type spatial;
// Haze on the far escarpments is baked into their palette. Lighting a 600 m
// mountain like a nearby white wall erases the boundary against the skyline.
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec3 low : source_color = vec3(.26,.32,.27);
uniform vec3 heather : source_color = vec3(.32,.35,.28);
uniform vec3 scree : source_color = vec3(.37,.40,.38);
uniform vec3 distance_tint : source_color = vec3(.55,.61,.61);
uniform sampler2D slope_detail : source_color, repeat_enable, filter_linear_mipmap;
varying vec3 p;
varying vec3 n;
void vertex(){ p=VERTEX; n=NORMAL; }
void fragment(){
	float fold=.5+.5*sin(p.x*.045+p.z*.061+2.*sin(p.z*.019));
	float outcrop=smoothstep(.40,.71,1.-abs(normalize(n).y))*.74;
	vec3 close=mix(mix(low,heather,fold),scree,outcrop);
	vec3 norm=normalize(n); float facing=.67+.30*abs(dot(norm,normalize(vec3(-.65,.73,-.21))));
	float strata=texture(slope_detail,p.xz*.023+vec2(.012,-.019)*p.y).r;
	close*=facing*(.79+.56*strata);
	float wash=clamp(.33+(length(VERTEX)-70.)/780.,.32,.91);
	ALBEDO=mix(close,distance_tint,wash);
}
