import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// ── 对齐底座 ────────────────────────────────────────────────────────────────
// 折射靠"在同一坐标空间里把同一张背景重画一遍、按位置反偏移"伪造背板采样。
// 所以宿主必须在根部接好这两根线：appBackdropSize（根尺寸）+ coordinateSpace("appRoot")。

public struct AppBackdropSizeKey: EnvironmentKey {
    public static let defaultValue = CGSize(width: 1440, height: 900)
}

public extension EnvironmentValues {
    /// app 根部的尺寸。在根 GeometryReader 里 `.environment(\.appBackdropSize, proxy.size)` 注入。
    var appBackdropSize: CGSize {
        get { self[AppBackdropSizeKey.self] }
        set { self[AppBackdropSizeKey.self] = newValue }
    }
}

/// 折射要采样的背景内容。
///
/// 关键：背景层和折射层必须画**同一个东西**（同尺寸、同缩放、同锚点 top-leading），
/// 像素才能一一对齐。所以宿主画背景、折射圆采样，都得过这同一个 `fill(size:)`。
///
/// - 把一张图片放进 `Resources/`，并设 `imageResourceName` 为它的文件名 → 用图片当背景。
/// - 设为 `nil`（或图片找不到）→ 自动回退到程序生成的彩色图案（零资源、无版权）。
public enum LiquidGlassBackdrop {
    /// 背景图资源文件名（放 Resources/，含扩展名）。设为 nil 用程序生成图案兜底。
    /// 换成自己的图：把这行字符串改成你的文件名即可。
    public static let imageResourceName: String? = "preview-bg.png"

    @ViewBuilder
    public static func fill(size: CGSize) -> some View {
        if let image = customImage {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .clipped()
        } else {
            DemoPattern()
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .clipped()
        }
    }

    private static var customImage: Image? {
        #if canImport(AppKit)
        guard let name = imageResourceName else { return nil }
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        guard let url = Bundle.module.url(forResource: base, withExtension: ext.isEmpty ? nil : ext),
              let ns = NSImage(contentsOf: url) else { return nil }
        return Image(nsImage: ns)
        #else
        return nil
        #endif
    }
}

/// 兜底用的程序生成图案：暖白底 + 五块彩色光斑 + 细网格线。
/// 网格被折射掰弯、光斑边缘色散，最能直观展示透镜效果。
struct DemoPattern: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FDF7EE"), Color(hex: "EAF1FB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            colorBlob("FF9FB0", 0.16, 0.20, 320)
            colorBlob("FFD66B", 0.80, 0.16, 360)
            colorBlob("8FE6B4", 0.26, 0.80, 340)
            colorBlob("8FB8FF", 0.84, 0.78, 360)
            colorBlob("D79BFF", 0.54, 0.48, 300)
            DemoGrid()
        }
    }

    private func colorBlob(_ hex: String, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> some View {
        RadialGradient(
            colors: [Color(hex: hex).opacity(0.50), Color(hex: hex).opacity(0)],
            center: UnitPoint(x: x, y: y),
            startRadius: 0,
            endRadius: r
        )
    }
}

private struct DemoGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 40
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            ctx.stroke(path, with: .color(Color(hex: "5B6B7A").opacity(0.16)), lineWidth: 1)
        }
    }
}
