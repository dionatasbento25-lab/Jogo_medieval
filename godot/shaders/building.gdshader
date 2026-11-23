// Construções low-poly com cor por vértice (estilo idle: cores um pouco mais vivas) + tinta da prévia.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert;
uniform vec4 tint = vec4(0.0);
varying vec3 vnv;
void vertex() { vnv = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz; }
void fragment() {
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(.3, .59, .11)); c = mix(vec3(l), c, 1.18) * 1.04;
	c = mix(c, tint.rgb, tint.a);
	ALBEDO = clamp(c, 0.0, 1.0);
	vec3 nv = normalize(vnv); if (dot(nv, VIEW) < 0.0) nv = -nv;
	NORMAL = nv;
	ROUGHNESS = 0.85; SPECULAR = 0.2;
}
