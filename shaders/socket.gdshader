shader_type canvas_item;

uniform vec4 amber_color: source_color = vec4(0.91, 0.72, 0.42, 1.0);
uniform vec4 brass_color: source_color = vec4(0.71, 0.45, 0.2, 1.0);
uniform vec4 teal_color: source_color = vec4(0.06, 0.16, 0.2, 1.0);
uniform bool is_lit = true;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // Create brass ring
    float ring_inner = 0.25;
    float ring_outer = 0.45;
    float ring_width = ring_outer - ring_inner;
    
    // Ring shape with soft edges
    float ring_shape = smoothstep(ring_inner - 0.02, ring_inner, dist) * 
                       (1.0 - smoothstep(ring_outer - 0.02, ring_outer, dist));
    
    // Inner hole (dark teal)
    float hole_shape = 1.0 - smoothstep(ring_inner - 0.05, ring_inner, dist);
    
    // Amber glow in center when lit
    float glow_radius = is_lit ? 0.2 : 0.0;
    float glow_shape = 1.0 - smoothstep(0.0, glow_radius, dist);
    vec3 glow = amber_color.rgb * glow_shape * 0.8;
    
    // Combine colors
    vec3 final_color = brass_color.rgb * ring_shape + 
                       teal_color.rgb * hole_shape + 
                       glow;
    
    // Add subtle metallic sheen to ring
    float sheen = sin(dist * 40.0) * 0.1;
    final_color += sheen * ring_shape;
    
    COLOR = vec4(final_color, ring_shape + hole_shape + glow_shape * 0.5);
}