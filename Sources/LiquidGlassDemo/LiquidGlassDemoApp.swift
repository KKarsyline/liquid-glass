import SwiftUI
import LiquidGlassKit

@main
struct LiquidGlassDemoApp: App {
    var body: some Scene {
        WindowGroup("LiquidGlassKit Demo") {
            DemoRootView()
                .frame(minWidth: 880, minHeight: 620)
        }
    }
}

struct DemoRootView: View {
    var body: some View {
        GeometryReader { root in
            ZStack {
                // 背景：和折射层用同一个 LiquidGlassBackdrop.fill（保证像素一一对齐）
                LiquidGlassBackdrop.fill(size: root.size)

                DemoStage()
            }
            .coordinateSpace(name: "appRoot")
            .environment(\.appBackdropSize, root.size)
        }
    }
}

struct DemoStage: View {
    @State private var ballPos = CGPoint(x: 340, y: 240)
    @State private var diameter: CGFloat = 220
    @State private var strength: CGFloat = 30
    @State private var dispersion: CGFloat = 1.2
    @State private var rimWidth: CGFloat = 0.55
    @State private var magnify: CGFloat = 0.5
    @State private var backdropBlur: CGFloat = 0

    var body: some View {
        ZStack {
            draggableBall
            VStack {
                hint
                Spacer()
                sliders
            }
        }
    }

    private var hint: some View {
        Text("拖动大球，看它实时折射背后的背景")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.black.opacity(0.28), in: Capsule())
            .padding(.top, 18)
    }

    private var draggableBall: some View {
        ZStack {
            LiquidGlassLens(
                isActive: true,
                strength: strength,
                dispersion: dispersion,
                magnify: magnify,
                rimWidth: rimWidth,
                radiusScale: 1.0,
                backdropBlur: backdropBlur
            )
            .frame(width: diameter, height: diameter)

            // 透明命中层：折射透镜本身不接收点击，靠这层让球能拖
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: diameter, height: diameter)
        }
        .overlay(
            Circle()
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.6)
                .frame(width: diameter, height: diameter)
        )
        .shadow(color: .black.opacity(0.18), radius: 14, y: 7)
        .position(ballPos)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("appRoot"))
                .onChanged { ballPos = $0.location }
        )
    }

    private var sliders: some View {
        VStack(alignment: .leading, spacing: 8) {
            sliderRow("扭曲 strength", $strength, 0...60)
            sliderRow("色散 dispersion", $dispersion, 0...3)
            sliderRow("过渡 rimWidth", $rimWidth, 0.2...0.95)
            sliderRow("放大 magnify", $magnify, 0...1.5)
            sliderRow("背景模糊 blur", $backdropBlur, 0...8)
            sliderRow("直径 size", $diameter, 80...340)
        }
        .padding(18)
        .frame(width: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.4), lineWidth: 0.5)
        )
        .padding(.bottom, 24)
    }

    private func sliderRow(_ label: String, _ value: Binding<CGFloat>, _ range: ClosedRange<CGFloat>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11))
                .frame(width: 116, alignment: .leading)
                .foregroundStyle(Color(hex: "3C434B"))
            Slider(value: value, in: range)
            Text(String(format: "%.2f", Double(value.wrappedValue)))
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 40, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}
