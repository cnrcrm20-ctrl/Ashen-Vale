shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void vertex() {
 vec3 scale_ = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0]*scale_.x, INV_VIEW_MATRIX[1]*scale_.y, INV_VIEW_MATRIX[2]*scale_.z, MODEL_MATRIX[3]);
}
void fragment() {
 vec2 uv = UV*2.-1.;
 float edge = length(uv) + .11 * sin(uv.y*9.+TIME*.65) * cos(uv.x*6.);
 ALBEDO = vec3(.52,.51,.46);
 ALPHA = (1.-smoothstep(.09,1.,edge))*.125;
}
