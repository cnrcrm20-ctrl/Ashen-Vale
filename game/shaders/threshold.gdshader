shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment(){vec2 q=(UV-.5)*2.;float r=length(q);float ripple=.5+.5*sin(r*30.-TIME*4.4+sin(q.y*9.+TIME)*1.45);float edge=smoothstep(.3,.96,r);ALBEDO=mix(vec3(.15,.45,.43),vec3(.94,.78,.46),ripple*edge);ALPHA=(.12+edge*.42+ripple*.12)*(1.-smoothstep(.94,1.,r));}
