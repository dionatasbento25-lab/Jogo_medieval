// Árvores instanciadas (MultiMesh). INSTANCE_CUSTOM.x = tom; neve nas copas do norte.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert;
uniform vec2 half_size = vec2(1536.0, 1082.5);
varying vec3 vnv;
varying vec3 vcol;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float lat = (wp.z + half_size.y) / (2.0 * half_size.y);
	float cold = smoothstep(.40, .06, lat);
	vcol = mix(COLOR.rgb * INSTANCE_CUSTOM.x, vec3(.90, .93, .97), smoothstep(.35, .9, cold) * smoothstep(.05, .8, wn.y) * .7 * step(.8, VERTEX.y));
	vnv = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}
void fragment() {
	vec3 c = vcol; float l = dot(c, vec3(.3, .59, .11)); c = mix(vec3(l), c, 1.12);
	ALBEDO = clamp(c, 0.0, 1.0);
	vec3 nv = normalize(vnv); if (dot(nv, VIEW) < 0.0) nv = -nv; NORMAL = nv;
	ROUGHNESS = 0.9; SPECULAR = 0.15;
}
