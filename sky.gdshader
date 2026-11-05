shader_type sky;
// Ciel des mondes : dégradé jour/nuit, disque du soleil, lune et étoiles.
// Les uniforms sont pilotés par world.gd (cycle jour/nuit).

uniform vec4 day_top : source_color = vec4(0.05, 0.05, 0.12, 1.0);
uniform vec4 day_horizon : source_color = vec4(0.12, 0.05, 0.2, 1.0);
uniform vec4 night_top : source_color = vec4(0.0, 0.0, 0.02, 1.0);
uniform vec4 night_horizon : source_color = vec4(0.02, 0.02, 0.05, 1.0);
uniform vec4 ground_bottom : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float night : hint_range(0.0, 1.0) = 0.0;   // 0 = plein jour, 1 = pleine nuit
uniform vec3 moon_dir = vec3(0.0, 1.0, 0.0);        // direction VERS la lune
uniform vec4 moon_color : source_color = vec4(0.85, 0.9, 1.0, 1.0);
uniform float star_density : hint_range(0.0, 0.05) = 0.012;
uniform float star_seed = 0.0;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3) + star_seed);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 dir = EYEDIR;
	float h = dir.y;
	vec3 top = mix(day_top.rgb, night_top.rgb, night);
	vec3 hor = mix(day_horizon.rgb, night_horizon.rgb, night);

	vec3 col;
	if (h >= 0.0) {
		col = mix(hor, top, pow(clamp(h, 0.0, 1.0), 0.5));
	} else {
		col = mix(hor, ground_bottom.rgb, clamp(-h * 4.0, 0.0, 1.0));
	}

	// Soleil : disque + halo (disparaît quand la lumière est éteinte, la nuit)
	if (LIGHT0_ENABLED) {
		float d = dot(dir, LIGHT0_DIRECTION);
		float disc = smoothstep(0.9990, 0.9995, d);
		float glow = pow(max(d, 0.0), 48.0) * 0.35;
		col += LIGHT0_COLOR * LIGHT0_ENERGY * (disc * 4.0 + glow);
	}

	if (h > 0.0 && night > 0.0) {
		// Étoiles : une étoile possible par cellule d'une grille 3D sur la sphère
		vec3 p = dir * 220.0;
		vec3 cell = floor(p);
		float r = hash(cell);
		if (r > 1.0 - star_density) {
			vec3 center = cell + 0.5;
			float dist = length(p - center);
			float star = smoothstep(0.35, 0.0, dist) * (0.5 + 0.5 * hash(cell + 7.0));
			col += vec3(star) * night * smoothstep(0.0, 0.25, h);
		}
		// Lune : disque net + halo doux
		float m = dot(dir, normalize(moon_dir));
		float moon = smoothstep(0.9975, 0.9980, m);
		float halo = pow(max(m, 0.0), 120.0) * 0.4;
		col += moon_color.rgb * (moon * 1.5 + halo) * night;
	}

	COLOR = col;
}
