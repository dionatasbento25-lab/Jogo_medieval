// Oceano até o horizonte: cor pela profundidade real, espuma na costa, reflexo do sol, gelo no norte.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;
uniform sampler2D nrm_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D det_tex : filter_linear_mipmap, repeat_enable;
uniform vec2 half_size = vec2(1536.0, 1082.5);
uniform float time = 0.0;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float cold_at(vec3 p) {
	float lat = (p.z + half_size.y) / (2.0 * half_size.y);
	float wob = sin(p.x * .011 + 1.3) * .035 + sin(p.x * .029 - p.z * .007) * .02;
	return smoothstep(.40, .03, lat + wob);
}
void fragment() {
	vec2 uv = (wpos.xz + half_size) / (2.0 * half_size);
	float h = -40.0;
	if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) h = texture(nrm_tex, uv).a * 50.0 - 40.0;
	float dd = clamp(-h / 24.0, 0.0, 1.0);
	vec3 col = mix(vec3(.17, .52, .56), vec3(.035, .19, .33), pow(dd, .55));
	vec2 w = vec2(time * .9, time * .6);
	vec3 n = normalize(vec3((texture(det_tex, wpos.xz * 0.045 + w * .004).r - .5) * .22, 1.0, (texture(det_tex, wpos.xz * 0.045 + vec2(.5, .27) - w * .003).r - .5) * .22));
	col = mix(col, vec3(.86, .92, .88), smoothstep(-1.3, -0.1, h) * (.38 + .12 * sin(time * 1.7 + wpos.x * .05)));
	float cw = cold_at(wpos); col = mix(col, col * vec3(.78, .88, 1.0) + vec3(.0, .02, .05), cw * .7);
	float ice = cw * cw * cw * smoothstep(-10.0, -1.5, h) * smoothstep(.70, .78, texture(det_tex, wpos.xz * 0.012 + vec2(.13, .71)).r);
	col = mix(col, vec3(.88, .93, .97), ice * .85);
	ALBEDO = col;
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ROUGHNESS = mix(0.12, 0.8, ice);
	SPECULAR = 0.6;
}
