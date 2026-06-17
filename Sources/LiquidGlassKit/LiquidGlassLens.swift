import SwiftUI

private let lensShaderLibrary: ShaderLibrary = {
    guard let url = Bundle.module.url(forResource: "LiquidGlassLens", withExtension: "metallib") else {
        return .default
    }
    return ShaderLibrary(url: url)
}()

public extension View {
    /// 把 `orbGlassLens` shader 作为 layerEffect 套上去。
    /// radius = 半个 frame，让扭曲带正好压在可见圆的边缘（不会落到被裁掉的圆外）。
    func orbGlassLensLayer(
        isActive: Bool,
        radiusScale: CGFloat,
        strength: CGFloat,
        dispersion: CGFloat,
        magnify: CGFloat,
        rimWidth: CGFloat
    ) -> some View {
        let reach = strength * (1 + dispersion) + magnify * 60
        return visualEffect { content, proxy in
            let radius = min(proxy.size.width, proxy.size.height) * 0.5 * radiusScale
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            return content.layerEffect(
                lensShaderLibrary.orbGlassLens(
                    .float2(Float(center.x), Float(center.y)),
                    .float(Float(radius)),
                    .float(isActive ? Float(strength) : 0),
                    .float(Float(dispersion)),
                    .float(isActive ? Float(magnify) : 0),
                    .float(Float(rimWidth))
                ),
                maxSampleOffset: CGSize(width: reach, height: reach),
                isEnabled: isActive
            )
        }
    }
}

/// 实时折射透镜（圆形）。
///
/// 把 `LiquidGlassBackdrop` 的同一张背景，在 "appRoot" 坐标空间里重新画一遍、按本视图的
/// 绝对位置反向偏移，再过 `orbGlassLens` shader → 得到折射 + 色散，且采样区域锁定在背景上、
/// 不随按钮移动而漂移。需要宿主在根部接好 appBackdropSize + coordinateSpace("appRoot")。
public struct LiquidGlassLens: View {
    @Environment(\.appBackdropSize) private var appBackdropSize

    public var isActive: Bool
    public var strength: CGFloat       // 完全扭曲层的扭曲幅度
    public var dispersion: CGFloat     // RGB 色散强度
    public var magnify: CGFloat        // 中心放大（鱼眼感；附件球用 0）
    public var rimWidth: CGFloat       // 过渡层起点（0→1，越大越宽越软）
    public var radiusScale: CGFloat    // 透镜半径占整圆比例（1.0 = 扭曲带压在边缘）
    public var sampleOffset: CGSize    // 用 .offset 上浮时校正采样位置
    public var backdropBlur: CGFloat   // 折射前对背景的模糊量（磨砂感）

    public init(
        isActive: Bool = true,
        strength: CGFloat = 18,
        dispersion: CGFloat = 0.7,
        magnify: CGFloat = 0,
        rimWidth: CGFloat = 0.72,
        radiusScale: CGFloat = 1.0,
        sampleOffset: CGSize = .zero,
        backdropBlur: CGFloat = 0
    ) {
        self.isActive = isActive
        self.strength = strength
        self.dispersion = dispersion
        self.magnify = magnify
        self.rimWidth = rimWidth
        self.radiusScale = radiusScale
        self.sampleOffset = sampleOffset
        self.backdropBlur = backdropBlur
    }

    public var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .named("appRoot"))

            ZStack(alignment: .topLeading) {
                LiquidGlassBackdrop.fill(size: appBackdropSize)
                    .saturation(1.08)
                    .blur(radius: backdropBlur)
                    .offset(x: -frame.minX - sampleOffset.width, y: -frame.minY - sampleOffset.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .orbGlassLensLayer(
                isActive: isActive,
                radiusScale: radiusScale,
                strength: strength,
                dispersion: dispersion,
                magnify: magnify,
                rimWidth: rimWidth
            )
            .clipShape(Circle())
            .allowsHitTesting(false)
        }
    }
}
