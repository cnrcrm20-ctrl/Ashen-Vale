shader_type spatial;
render_mode cull_disabled;
uniform sampler2D capillary : hint_normal, repeat_enable, filter_linear_mipmap;
uniform vec3 channel_tint : source_color = vec3(.17,.235,.206);
uniform vec3 sky_tint : source_color = vec3(.40,.49,.47);
varying vec3 place;
void vertex(){
	place=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
	VERTEX.y+=.016*sin(place.z*1.5+place.x*.6+TIME*1.4)+.011*sin(place.x*2.1-TIME);
}
void fragment(){
	vec2 p=place.xz;
	vec2 first=texture(capillary,p*.76+vec2(TIME*.080,TIME*.015)).rg*2.-1.;
	mat2 turn=mat2(vec2(.80,.60),vec2(-.60,.80));
	vec2 second=turn* (texture(capillary,turn*p*1.53-vec2(TIME*.10,.017*TIME)).rg*2.-1.);
	vec2 slope=.21*first+.11*second;
	NORMAL=normalize((VIEW_MATRIX*vec4(slope.x,1.,slope.y,0.)).xyz);
	float fresnel=pow(1.-clamp(dot(NORMAL,VIEW),0.,1.),2.7);
	float bed=.5+.5*sin(p.x*.67+sin(p.y*.82+p.x*.23));
	ALBEDO=mix(channel_tint*(.86+.20*bed),sky_tint,.09+.55*fresnel);
	ROUGHNESS=.31+.085*first.y; SPECULAR=.36; METALLIC=.015;
}
