// Aldeões: um modelo articulado instanciado (MultiMesh).
// UV.x = peça + 10*acessório; UV.y = marcador (1 roupa, 2 cabelo); UV2.x = sombra.
// INSTANCE_CUSTOM: x = fase do passo, y = modo + 4*profissão + 32*carga, z = cor da roupa (paleta), w = cabelo.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert;
uniform vec3 shirts[14];
varying vec3 vcol;
varying vec3 vnv;
vec3 rotX(vec3 p, vec3 piv, float a) { p -= piv; float c = cos(a), s = sin(a); return vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c) + piv; }
void vertex() {
	float part = mod(UV.x, 10.0), acc = floor(UV.x / 10.0 + 0.01);
	float packed = floor(INSTANCE_CUSTOM.y + 0.5);
	float mode = mod(packed, 4.0), role = mod(floor(packed / 4.0), 8.0), carry = floor(packed / 32.0);
	float ph = INSTANCE_CUSTOM.x;
	vec3 p = VERTEX, col = COLOR.rgb;
	if (UV.y > 1.5) {
		float hw = INSTANCE_CUSTOM.w;
		col = mix(vec3(.30, .18, .10), mix(vec3(.85, .62, .28), vec3(.12, .08, .06), step(.5, hw)), fract(hw * 2.0)) * UV2.x;
	} else if (UV.y > 0.5) {
		col = shirts[int(INSTANCE_CUSTOM.z + .5)] * UV2.x;
	}
	float vis = 1.0;
	if (acc > 0.5 && acc < 4.5) vis = (abs(acc - role) < 0.5 && carry < 0.5) ? 1.0 : 0.0;
	if (acc > 5.5 && acc < 6.5) vis = abs(role - 3.0) < 0.5 ? 1.0 : 0.0;
	if (acc > 4.5 && acc < 5.5) {
		vis = carry > 0.5 ? 1.0 : 0.0;
		col = carry < 1.5 ? vec3(.55, .36, .2) : (carry < 2.5 ? vec3(.62, .62, .6) : (carry < 3.5 ? vec3(.9, .8, .5) : vec3(1.0, .82, .25)));
	}
	float walk = (mode > 0.5 && mode < 1.5) ? 1.0 : 0.0, work = mode > 1.5 ? 1.0 : 0.0;
	float sw = sin(ph) * 0.75 * walk;
	float bob = abs(sin(ph)) * 0.09 * walk + sin(ph * 0.5) * 0.025 * (1.0 - walk) * (1.0 - work);
	if (part > 0.5 && part < 1.5) p = rotX(p, vec3(0.0, .62, 0.0), sw);
	if (part > 1.5 && part < 2.5) p = rotX(p, vec3(0.0, .62, 0.0), -sw);
	float hold = carry > 0.5 ? -1.25 : 0.0;
	float chop = work * (-1.6 + 1.3 * smoothstep(-0.2, 1.0, sin(ph * 2.0)));
	if (part > 2.5 && part < 3.5) p = rotX(p, vec3(0.0, 1.18, 0.0), (carry > 0.5 ? hold : -sw * 0.8) + work * 0.2);
	if (part > 3.5 && part < 4.5) p = rotX(p, vec3(0.0, 1.18, 0.0), carry > 0.5 ? hold : (work > 0.5 ? chop : sw * 0.8));
	if (part < 0.5 && work > 0.5 && VERTEX.y > 1.0) p = rotX(p, vec3(0.0, .7, 0.0), 0.12 + 0.12 * sin(ph * 2.0));
	p *= vis; p.y += bob * vis;
	VERTEX = p;
	vcol = col;
	vnv = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}
void fragment() {
	vec3 c = vcol * 1.06; float l = dot(c, vec3(.3, .59, .11)); c = mix(vec3(l), c, 1.2);
	ALBEDO = clamp(c, 0.0, 1.0);
	vec3 nv = normalize(vnv); if (dot(nv, VIEW) < 0.0) nv = -nv; NORMAL = nv;
	ROUGHNESS = 0.8; SPECULAR = 0.2;
}
