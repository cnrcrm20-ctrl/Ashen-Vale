shader_type canvas_item;
uniform sampler2D behind : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 ink : source_color = vec4(.064,.093,.108,.76);
void fragment(){
 vec2 edge=min(UV,1.-UV)/max(fwidth(UV),vec2(.0001));
 float rim=1.-smoothstep(.5,1.7,min(edge.x,edge.y));
 vec3 blurred=textureLod(behind,SCREEN_UV,2.5).rgb;
 COLOR=vec4(mix(mix(blurred,ink.rgb,ink.a),vec3(.64,.53,.38),rim*.55),.98);
}
