shader_type spatial;
// Surface du portail : tourbillon de spirales bleu/violet, bord adouci, cœur lumineux.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 color_a : source_color = vec4(0.25, 0.45, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.75, 0.25, 1.0, 1.0);
uniform float swirl_speed = 1.5;   // vitesse de rotation
uniform float twist = 7.0;         // à quel point les bras de la spirale s'enroulent
uniform float arms = 3.0;          // nombre de bras
uniform float intensity = 1.6;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	if (r > 1.0) {
		discard;
	}
	float angle = atan(uv.y, uv.x);
	float spiral = sin(angle * arms + r * twist - TIME * swirl_speed);
	float bands = smoothstep(-0.3, 1.0, spiral);
	float core = pow(1.0 - r, 3.0);
	float edge = smoothstep(1.0, 0.8, r);

	vec3 col = mix(color_a.rgb, color_b.rgb, bands) * (0.3 + bands * 0.9) + vec3(core);
	ALBEDO = col * intensity;
	ALPHA = edge * (0.55 + 0.45 * bands);
}
