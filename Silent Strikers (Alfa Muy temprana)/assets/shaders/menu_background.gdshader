shader_type canvas_item;

uniform vec2 light_position;
uniform float light_radius = 200.0;
uniform float flicker_strength = 10.0;
uniform float flicker_value = 0.0;
uniform float softness = 0.5;

void fragment() {
    vec2 uv = FRAGCOORD.xy;
    float radius = light_radius + flicker_value * flicker_strength;
    float dist = distance(uv, light_position);
    float alpha = clamp((dist - radius) / (radius * softness), 0.0, 1.0);
    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
