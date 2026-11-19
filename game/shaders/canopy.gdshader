shader_type spatial;
render_mode cull_disabled;
uniform sampler2D foliage : source_color, filter_linear_mipmap, repeat_enable;
void vertex(){
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 float flex=smoothstep(1.,12.,VERTEX.y);
 VERTEX.x+=flex*(sin(TIME*1.45+p.z*.38)+.4*sin(TIME*2.1+p.x*.76))*.055;
}
void fragment(){vec4 c=texture(foliage,UV);ALBEDO=c.rgb;ALPHA=c.a;ALPHA_SCISSOR_THRESHOLD=.46;ROUGHNESS=.91;}
