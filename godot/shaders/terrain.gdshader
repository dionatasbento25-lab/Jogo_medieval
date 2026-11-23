// Terreno do continente — porte do shader "fsT" do mapa original.
// Cores calculadas em sRGB, como no original (o renderizador Compatibility trabalha direto em sRGB).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_tex : filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D nrm_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D det_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D splat_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D pat_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D bord_tex : filter_linear_mipmap, repeat_disable;
uniform sampler2D prov_tex : filter_nearest, repeat_disable;
uniform sampler2D look_tex : filter_nearest, repeat_disable;
uniform vec2 half_size = vec2(1536.0, 1082.5);
uniform float time = 0.0;
uniform float fill = 0.5;
uniform float pix = 0.001;
uniform float tex_w = 1.5;
uniform vec3 lines = vec3(0.45, 1.0, 1.0);
uniform vec4 grid = vec4(0.0);   // x,z do cursor, raio da grade, modo construção
uniform vec4 sel = vec4(0.0);    // x,z e meio-lado do destaque
uniform float det_far = 240.0;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = NORMAL;
}

float cold_at(vec3 p) {
	float lat = (p.z + half_size.y) / (2.0 * half_size.y);
	float wob = sin(p.x * .011 + 1.3) * .035 + sin(p.x * .029 - p.z * .007) * .02;
	return smoothstep(.40, .03, lat + wob);
}

void fragment() {
	vec2 uv = (wpos.xz + half_size) / (2.0 * half_size);
	vec4 nm = texture(nrm_tex, uv);
	vec3 n = vec3(nm.r * 2.0 - 1.0, 0.0, nm.g * 2.0 - 1.0);
	n.y = sqrt(max(1.0 - n.x * n.x - n.z * n.z, 0.05));
	vec3 alb = texture(albedo_tex, uv).rgb;
	float d = distance(wpos, CAMERA_POSITION_WORLD), df = 1.0 - smoothstep(70.0, det_far, d);
	float steep = smoothstep(.82, .60, n.y);
	float det = texture(det_tex, wpos.xz * 0.031 + vec2(0.37, 0.11)).r;
	vec3 far_c = mix(alb, vec3(.47, .44, .38) * (.75 + det * .5), steep * .75) * (0.9 + det * 0.2);
	vec4 p = texture(pat_tex, wpos.xz * 0.085) * .62 + texture(pat_tex, wpos.xz * 0.0215 + vec2(.31, .17)) * .38;
	vec4 w = texture(splat_tex, uv); w.b = max(w.b, steep);
	w *= vec4(.3) + p * 1.4; w = w * w * w + vec4(0.00001); w /= dot(w, vec4(1.0));
	vec3 tint = mix(alb, vec3(.36, .52, .24), .18);
	vec3 cG = tint * (.66 + .70 * p.r);
	vec3 cS = mix(alb, vec3(.80, .68, .46), .40) * (.74 + .52 * p.g);
	vec3 cR = mix(alb, vec3(.47, .44, .39), .70) * (.50 + .95 * p.b);
	vec3 cW = mix(alb, vec3(.93, .95, .97), .75) * (.86 + .18 * p.a);
	vec3 near_c = cG * w.r + cS * w.g + cR * w.b + cW * w.a;
	vec3 base = mix(far_c, near_c, df);
	{
		float c = cold_at(wpos) + (p.a - .5) * .10;
		float alt = smoothstep(28.0, 62.0, wpos.y);
		float flat_ = smoothstep(.55, .86, n.y);
		float frost = smoothstep(.02, .45, c);
		base = mix(base, dot(base, vec3(.3, .59, .11)) * vec3(.84, .93, .98) * 1.12, frost * .32);
		float sn = smoothstep(.55, 1.0, c * .95 + alt * .85 + (p.a - .5) * .5 + (det - .5) * .3) * mix(.3, 1.0, flat_);
		base = mix(base, vec3(.90, .93, .97) * (.92 + .10 * p.a), sn * .92);
	}
	float lum = dot(alb, vec3(.3, .59, .11)), fm = smoothstep(.25, .17, lum) * step(alb.r, alb.g);
	float cn = texture(det_tex, wpos.xz * 0.07).r * .65 + texture(det_tex, wpos.xz * 0.19 + vec2(.2, .6)).r * .35;
	base *= mix(1.0, .58 + cn * .8, fm * clamp(d / 260.0, 0.15, 1.0));
	// mapa político: id da província → cor do dono (tabela) + fronteiras
	ivec2 ps = textureSize(prov_tex, 0);
	vec2 rg = texelFetch(prov_tex, clamp(ivec2(uv * vec2(ps)), ivec2(0), ps - 1), 0).rg;
	int id = int(rg.r * 255.0 + .5) + int(rg.g * 255.0 + .5) * 256;
	vec4 pol = texelFetch(look_tex, ivec2(id, 0), 0);
	vec4 bd = texture(bord_tex, uv) * 16.0;
	float landP = id > 0 ? 1.0 : 0.0, selP = step(.9, pol.a), fp = max(d * pix / tex_w, .04);
	float mine = step(.555, pol.a) * step(pol.a, .62);
	base = mix(base, pol.rgb, landP * fill);
	float rm = bd.a / 16.0;
	float water_m = 0.0;
	if (rm > 0.06) {
		float wat = smoothstep(.30, .52, rm), bank = smoothstep(.06, .30, rm) * (1.0 - wat);
		vec3 wetB = mix(base * .62, vec3(.42, .38, .27), .35); base = mix(base, wetB, bank * .8);
		if (wat > 0.0) {
			float e = 1.0 / 2048.0;
			vec2 g = vec2(texture(bord_tex, uv + vec2(e, 0.0)).a - texture(bord_tex, uv - vec2(e, 0.0)).a, texture(bord_tex, uv + vec2(0.0, e * 2.0)).a - texture(bord_tex, uv - vec2(0.0, e * 2.0)).a);
			vec2 nrm2 = length(g) > 1e-4 ? normalize(g) : vec2(0.0, 1.0), tg = vec2(-nrm2.y, nrm2.x);
			vec2 q = vec2(dot(wpos.xz, tg), dot(wpos.xz, nrm2));
			float r1 = texture(det_tex, q * vec2(.10, .30) + vec2(-time * .06, 0.0)).r, r2 = texture(det_tex, q * vec2(.21, .55) + vec2(-time * .11, .37)).r;
			n = normalize(mix(n, normalize(vec3((r1 - .5) * .30 * tg.x + (r2 - .5) * .18, 1.0, (r1 - .5) * .30 * tg.y + (r2 - .5) * .18)), wat));
			vec3 wc = mix(vec3(.20, .48, .52), vec3(.07, .27, .37), smoothstep(.52, .95, rm));
			wc = mix(wc, vec3(.80, .86, .88), (1.0 - smoothstep(.30, .42, rm)) * .35);
			wc = mix(wc, vec3(.80, .88, .94) * (.9 + .12 * r1), smoothstep(.55, .9, cold_at(wpos)) * .85);
			base = mix(base, wc, wat); water_m = wat;
		}
	}
	float bwP = max(fp * .9, .55), bwH = max(fp * 2.6, 1.4), bwR = max(fp * 3.4, 1.9);
	float lp = 1.0 - smoothstep(bwP * .5, bwP * .5 + max(fp * .8, .5), bd.r);
	float lh = 1.0 - smoothstep(bwH, bwH + max(fp, .6), bd.g);
	float gh = (1.0 - smoothstep(bwH, bwH + max(fp * 9.0, 6.0), bd.g)) * (1.0 - lh);
	float lr = 1.0 - smoothstep(bwR, bwR + max(fp, .6), bd.b);
	float er = 1.0 - smoothstep(max(fp * .7, .4), max(fp * .7, .4) + max(fp * .8, .5), abs(bd.b - bwR));
	vec3 own = pol.rgb, hc = mix(own * 1.25, vec3(1.0), .22), parch = vec3(.95, .88, .68), gold = vec3(.96, .79, .40);
	base = mix(base, parch, lp * lines.x * landP * .55);
	base = mix(base, hc, gh * lines.y * landP * .35);
	base = mix(base, hc, lh * lines.y * landP * .92);
	base = mix(base, mix(gold, vec3(1.0, .93, .70), .25 * smoothstep(bwR, 0.0, bd.b)), lr * lines.z * landP * .95);
	base = mix(base, vec3(.30, .20, .09), er * lines.z * landP * .55);
	float ew = max(fp * 2.4, 1.8), edge = smoothstep(.45, .95, bd.r) * (1.0 - smoothstep(ew, ew + max(fp, .6), bd.r));
	base = mix(base, vec3(1.0, .85, .42), selP * (.14 * smoothstep(.5, 1.5, bd.r) + .75 * edge));
	// city builder: área do seu reino, grade e destaque da seleção
	if (grid.w > 0.5) base = mix(base, base * vec3(.58, .58, .64), (1.0 - mine) * landP * .6);
	if (grid.z > 0.0) {
		vec2 gg = fract(wpos.xz / 4.0); vec2 g2 = min(gg, 1.0 - gg);
		float ln = 1.0 - smoothstep(0.0, 0.06, min(g2.x, g2.y));
		float fade = 1.0 - smoothstep(grid.z * .6, grid.z, distance(wpos.xz, grid.xy));
		base = mix(base, vec3(1.0, .97, .85), ln * fade * .35 * mine);
	}
	if (sel.z > 0.0) {
		vec2 qq = abs(wpos.xz - sel.xy); float mm = max(qq.x, qq.y);
		float r = 1.0 - smoothstep(0.0, 0.5, abs(mm - sel.z));
		base = mix(base, vec3(1.0, .95, .5), r * (.6 + .3 * sin(time * 5.0)));
	}
	// névoa fria do norte (vales)
	float c2 = cold_at(wpos);
	if (c2 > 0.0) {
		float low = 1.0 - smoothstep(1.0, 16.0, wpos.y);
		float wisp = .72 + .28 * sin(wpos.x * .013 + sin(wpos.z * .009) * 2.5) * sin(wpos.z * .011 + wpos.x * .004);
		base = mix(base, vec3(.82, .87, .90), c2 * low * wisp * (1.0 - smoothstep(220.0, 750.0, d)) * .4);
	}
	ALBEDO = clamp(base, 0.0, 1.0);
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ROUGHNESS = mix(0.95, 0.12, water_m);
	SPECULAR = mix(0.25, 0.7, water_m);
	AO = clamp(nm.b * 1.1, 0.0, 1.0);
	AO_LIGHT_AFFECT = 0.5;
}
