#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// ── 玻璃珠透镜：中心放大 + 边缘强折射 + RGB 色散 + 边缘模糊 ──
// 三圈解耦：rimWidth 控制过渡层起点(宽软渐变)，高次幂让"完全扭曲"只在最外薄圈拉满。
//
// 重新编译（改了本文件后跑一次）：
//   xcrun -sdk macosx metal -o Sources/LiquidGlassKit/Resources/LiquidGlassLens.metallib \
//         Sources/LiquidGlassKit/Shaders/LiquidGlassLens.metal
[[ stitchable ]] half4 orbGlassLens(
    float2 position,
    SwiftUI::Layer layer,
    float2 center,
    float radius,
    float strength,
    float dispersion,
    float magnify,
    float rimWidth
) {
    float2 delta = position - center;
    float dist = length(delta);
    if (dist > radius || radius <= 0.0) {
        return layer.sample(position);
    }

    float n = dist / radius;                       // 0 中心 .. 1 边缘
    float2 dir = dist > 0.001 ? delta / dist : float2(0.0, 0.0);

    float bulge = 1.0 - n * n;
    float magPull = magnify * radius * 0.42 * bulge;

    float t = smoothstep(1.0 - rimWidth, 1.0, n);
    float band = pow(t, 2.6);              // 峰值不变，逼近更柔，过渡更平滑
    float edgeBend = strength * band;

    float2 baseOffset = -dir * (magPull + edgeBend);

    // 色散
    float chroma = dispersion * strength * 0.16 * band;
    float2 redOff  = baseOffset + dir * chroma;
    float2 blueOff = baseOffset - dir * chroma;

    // 边缘一圈模糊：5-tap 平均，模糊量随边缘带增长
    float blur = band * 2.0;
    float2 bx = float2(blur, 0.0);
    float2 by = float2(0.0, blur);

    half r = layer.sample(position + redOff).r * 0.52h
           + layer.sample(position + redOff + bx).r * 0.12h
           + layer.sample(position + redOff - bx).r * 0.12h
           + layer.sample(position + redOff + by).r * 0.12h
           + layer.sample(position + redOff - by).r * 0.12h;
    half g = layer.sample(position + baseOffset).g * 0.52h
           + layer.sample(position + baseOffset + bx).g * 0.12h
           + layer.sample(position + baseOffset - bx).g * 0.12h
           + layer.sample(position + baseOffset + by).g * 0.12h
           + layer.sample(position + baseOffset - by).g * 0.12h;
    half b = layer.sample(position + blueOff).b * 0.52h
           + layer.sample(position + blueOff + bx).b * 0.12h
           + layer.sample(position + blueOff - bx).b * 0.12h
           + layer.sample(position + blueOff + by).b * 0.12h
           + layer.sample(position + blueOff - by).b * 0.12h;
    half a = layer.sample(position + baseOffset).a;
    half4 col = half4(r, g, b, a);

    // 边缘高光（很薄，贴最外圈）
    half rim = half(smoothstep(0.90, 0.98, n) * (1.0 - smoothstep(0.995, 1.0, n)));
    col.rgb += rim * half3(0.12, 0.12, 0.11);
    return col;
}
