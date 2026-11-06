#version 440
// Digital glitch for the lock icon. Every effect scales with `intensity`, so 0 draws the clean icon.
// Rebuild after editing: tools/build-shaders.sh

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float intensity;
    float flash;
    vec4 tint;
};

layout(binding = 1) uniform sampler2D source;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float k = clamp(intensity, 0.0, 1.0);
    // Stepped time, so slices jump between positions instead of sliding.
    float t = floor(time * 18.0);

    // Horizontal bands shift sideways. More bands move as intensity rises.
    float bands = mix(12.0, 40.0, hash(vec2(t, 1.0)));
    float band = floor(uv.y * bands);
    float moving = step(1.0 - k * 0.85, hash(vec2(band, t)));
    float shift = (hash(vec2(band, t + 7.0)) - 0.5) * 0.28 * k * moving;
    // An occasional tear that moves the whole icon.
    float tear = step(0.9, hash(vec2(t, 3.0))) * (hash(vec2(t, 4.0)) - 0.5) * 0.1 * k;
    vec2 at = vec2(uv.x + shift + tear, uv.y);

    // Red and blue channels split apart (the texture is premultiplied).
    float split = 0.01 * k + 0.025 * k * moving;
    vec4 base = texture(source, at);
    vec4 red = texture(source, at + vec2(split, 0.0));
    vec4 blue = texture(source, at - vec2(split, 0.0));
    vec4 color = vec4(red.r, base.g, blue.b, max(base.a, max(red.a, blue.a)));

    // Scanlines, and bands that drop out for a frame.
    color *= 1.0 - 0.2 * k * step(0.5, fract(uv.y * 170.0));
    color *= 1.0 - step(1.0 - k * 0.22, hash(vec2(band, t + 13.0)));

    // Grain.
    color.rgb += (hash(uv * 512.0 + t) - 0.5) * 0.16 * k * color.a;

    // Tint flash: keystrokes flash the accent color, failures flash red.
    color.rgb = mix(color.rgb, tint.rgb * color.a, clamp(flash, 0.0, 1.0));

    fragColor = color * qt_Opacity;
}
