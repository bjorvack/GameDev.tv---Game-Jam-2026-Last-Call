shader_type canvas_item;

// Draws a small phone-jack plug, vertical, tip pointing DOWN.
// Composition (UV space, y=0 top, y=1 bottom):
//   * red rubber body:  rounded rectangle, centered horizontally,
//                       roughly upper half of the canvas
//   * brass shaft:      narrow rectangle directly below the body
//   * brass tip:        the very bottom (slightly tapered look via SDF)

uniform vec4 red_color: source_color = vec4(0.76, 0.29, 0.29, 1.0);
uniform vec4 brass_color: source_color = vec4(0.71, 0.45, 0.2, 1.0);

// Signed distance to an axis-aligned rounded box centered at `c`,
// half-extents `b`, corner radius `r`. Negative inside, positive outside.
float sd_rounded_box(vec2 p, vec2 c, vec2 b, float r) {
    vec2 d = abs(p - c) - b + vec2(r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void fragment() {
    vec2 uv = UV;

    // Rubber body: wider, in the upper half.
    float d_body = sd_rounded_box(uv, vec2(0.5, 0.32), vec2(0.18, 0.18), 0.05);
    float body_mask = 1.0 - smoothstep(-0.005, 0.005, d_body);

    // Brass shaft: narrow, below the body.
    float d_shaft = sd_rounded_box(uv, vec2(0.5, 0.66), vec2(0.07, 0.16), 0.02);
    float shaft_mask = 1.0 - smoothstep(-0.005, 0.005, d_shaft);

    // Brass tip: small bump at the very bottom.
    float d_tip = sd_rounded_box(uv, vec2(0.5, 0.86), vec2(0.05, 0.04), 0.03);
    float tip_mask = 1.0 - smoothstep(-0.005, 0.005, d_tip);

    float metal_mask = max(shaft_mask, tip_mask);
    float total_mask = max(body_mask, metal_mask);

    // Vertical highlight band on the rubber body for a subtle plastic sheen.
    float sheen = smoothstep(0.28, 0.32, uv.y) * (1.0 - smoothstep(0.38, 0.42, uv.y));
    vec3 body_col = red_color.rgb + vec3(0.18) * sheen;

    // Highlight on the shaft to read as brass.
    float metal_sheen = smoothstep(0.6, 0.64, uv.y) * (1.0 - smoothstep(0.7, 0.74, uv.y));
    vec3 metal_col = brass_color.rgb + vec3(0.2) * metal_sheen;

    vec3 final_color = mix(body_col, metal_col, metal_mask);

    COLOR = vec4(final_color, total_mask);
}
