shader_type canvas_item;

uniform vec4 mint_color: source_color = vec4(0.48, 0.68, 0.6, 1.0);
uniform vec4 brass_color: source_color = vec4(0.71, 0.45, 0.2, 1.0);
uniform bool is_on = true;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // Mint green circle
    float circle_radius = 0.35;
    float circle_shape = 1.0 - smoothstep(circle_radius - 0.05, circle_radius, dist);
    
    // Brass collar ring
    float collar_inner = 0.35;
    float collar_outer = 0.45;
    float collar_shape = smoothstep(collar_inner - 0.02, collar_inner, dist) * 
                         (1.0 - smoothstep(collar_outer - 0.02, collar_outer, dist));
    
    // Glow effect when on
    float glow_radius = is_on ? 0.5 : 0.0;
    float glow_shape = 1.0 - smoothstep(0.0, glow_radius, dist);
    vec3 glow = mint_color.rgb * glow_shape * 0.3;
    
    // Bright center when on
    float bright_center = is_on ? 0.8 : 0.5;
    vec3 center_color = mint_color.rgb * bright_center;
    
    // Combine colors
    vec3 final_color = brass_color.rgb * collar_shape + 
                       center_color * circle_shape + 
                       glow;
    
    COLOR = vec4(final_color, circle_shape + collar_shape + glow_shape * 0.5);
}