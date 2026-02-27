import SwiftUI

/// App icon — 1024×1024 SwiftUI canvas.
///
/// Design: Dark maroon pedal enclosure with 1/4" TS cables plugged into both sides,
/// and a single large rotary knob at center with an amber arc at ~70% travel.
///
/// To export the PNG for Assets.xcassets, run the app in Simulator and use the
/// debug export button in the MIDI sheet ("Export App Icon"). The PNG saves to
/// the app's Documents folder — retrieve via Xcode → Devices → Download Container.
///
/// Or right-click the #Preview canvas in Xcode and choose "Save Image".
struct AppIconView: View {

    // ── Geometry (all in points within the 1024×1024 canvas) ──────────────

    private let S: CGFloat = 1024

    // Enclosure bounds
    private let encL: CGFloat = 200, encR: CGFloat = 824
    private let encT: CGFloat = 80,  encB: CGFloat = 944
    private let encCorner: CGFloat = 90

    private var encW: CGFloat  { encR - encL }    // 624
    private var encH: CGFloat  { encB - encT }    // 864
    private var encCX: CGFloat { (encL + encR) / 2 }  // 512
    private var encCY: CGFloat { (encT + encB) / 2 }  // 512

    // Knob center
    private let knobX: CGFloat = 512
    private let knobY: CGFloat = 500

    // Knob radii
    private let arcR:   CGFloat = 132   // arc track path radius
    private let ringR:  CGFloat = 108   // grip ring outer radius
    private let rimR:   CGFloat = 78    // knurl inner / dome rim radius
    private let domeR:  CGFloat = 72    // dome body radius

    // Arc parameters
    private let arcStart: Double = -135
    private let arcEnd:   Double =  135
    private let arcFill:  Double =  0.70
    private var arcFilled: Double { arcStart + arcFill * (arcEnd - arcStart) }

    // Cable dimensions
    private let cableY: CGFloat = 512   // vertical center
    private let cableD: CGFloat = 52    // cable diameter
    private let barrelD: CGFloat = 72   // barrel height
    private let barrelW: CGFloat = 85   // barrel width (horizontal)

    // Colors
    private let amber = Color(red: 1.0, green: 0.70, blue: 0.22)

    // ── Body ──────────────────────────────────────────────────────────────

    var body: some View {
        ZStack {
            background
            leftCableBody
            rightCableBody
            enclosureFill
            leftBarrel
            rightBarrel
            enclosureBorder
            enclosureHighlight
            cornerScrews
            inputStrips
            knobView
        }
        .frame(width: 1024, height: 1024)
        .clipped()
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.22, green: 0.05, blue: 0.08), location: 0.0),
                .init(color: Color(red: 0.12, green: 0.03, blue: 0.04), location: 0.5),
                .init(color: Color(red: 0.05, green: 0.01, blue: 0.02), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - 1/4" Cables

    private var leftCableBody: some View {
        // Cable runs from canvas left edge into where the barrel sits.
        let w: CGFloat = encL + 10
        return RoundedRectangle(cornerRadius: cableD / 2)
            .fill(LinearGradient(
                colors: [Color(white: 0.23), Color(white: 0.11), Color(white: 0.23)],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: w, height: cableD)
            .position(x: w / 2, y: cableY)
    }

    private var rightCableBody: some View {
        let w: CGFloat = (S - encR) + 10
        return RoundedRectangle(cornerRadius: cableD / 2)
            .fill(LinearGradient(
                colors: [Color(white: 0.23), Color(white: 0.11), Color(white: 0.23)],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: w, height: cableD)
            .position(x: encR + w / 2 - 10, y: cableY)
    }

    // MARK: - Connector Barrels (centered on enclosure walls)

    private var leftBarrel: some View {
        barrelView.position(x: encL, y: cableY)
    }

    private var rightBarrel: some View {
        barrelView.position(x: encR, y: cableY)
    }

    private var barrelView: some View {
        ZStack {
            // Main barrel body — metallic silver gradient
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color(white: 0.80), Color(white: 0.54), Color(white: 0.36)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: barrelW, height: barrelD)
                .overlay(
                    // Threading grooves
                    Canvas { ctx, size in
                        var y: CGFloat = 10
                        while y < size.height - 8 {
                            var p = Path()
                            p.move(to:    CGPoint(x: 6, y: y))
                            p.addLine(to: CGPoint(x: size.width - 6, y: y))
                            ctx.stroke(p, with: .color(Color.black.opacity(0.13)), lineWidth: 1.2)
                            y += 9
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )

            // Left-edge specular highlight
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.30))
                .frame(width: 18, height: barrelD - 16)
                .offset(x: -(barrelW / 2 - 13))

            // Nut ring — flat threaded ring on the enclosure face (right half of barrel)
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color(white: 0.40), lineWidth: 3.5)
                .frame(width: 22, height: barrelD + 10)
                .offset(x: barrelW / 2 - 14)
        }
    }

    // MARK: - Enclosure

    private var enclosureFill: some View {
        RoundedRectangle(cornerRadius: encCorner)
            .fill(LinearGradient(
                stops: [
                    .init(color: Color(red: 0.30, green: 0.07, blue: 0.11), location: 0.0),
                    .init(color: Color(red: 0.22, green: 0.05, blue: 0.08), location: 0.45),
                    .init(color: Color(red: 0.17, green: 0.04, blue: 0.06), location: 1.0),
                ],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: encW, height: encH)
            .position(x: encCX, y: encCY)
    }

    private var enclosureBorder: some View {
        RoundedRectangle(cornerRadius: encCorner)
            .strokeBorder(Color.white.opacity(0.30), lineWidth: 5)
            .frame(width: encW, height: encH)
            .position(x: encCX, y: encCY)
    }

    private var enclosureHighlight: some View {
        RoundedRectangle(cornerRadius: encCorner - 3)
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.16), Color.clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: encW - 12, height: encH - 12)
            .position(x: encCX, y: encCY)
    }

    // MARK: - Corner Screws

    private var cornerScrews: some View {
        let inset: CGFloat = 56
        let pts = [
            CGPoint(x: encL + inset, y: encT + inset),
            CGPoint(x: encR - inset, y: encT + inset),
            CGPoint(x: encL + inset, y: encB - inset),
            CGPoint(x: encR - inset, y: encB - inset),
        ]
        return ZStack {
            ForEach(pts.indices, id: \.self) { i in
                screwView.position(x: pts[i].x, y: pts[i].y)
            }
        }
    }

    private var screwView: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(white: 0.58), Color(white: 0.28)],
                    center: UnitPoint(x: 0.35, y: 0.30),
                    startRadius: 0, endRadius: 14
                ))
                .frame(width: 28, height: 28)
            // Phillips crosshatch
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .frame(width: 13, height: 2.5)
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .frame(width: 2.5, height: 13)
            Circle()
                .strokeBorder(Color.black.opacity(0.30), lineWidth: 1)
                .frame(width: 28, height: 28)
        }
    }

    // MARK: - Input Strip (two red bands at top of enclosure face)

    private var inputStrips: some View {
        let inset = encCorner * 0.55
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.86, green: 0.22, blue: 0.15))
                .frame(width: encW - inset * 2, height: 14)
                .position(x: encCX, y: encT + 40)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.72, green: 0.16, blue: 0.11))
                .frame(width: encW - inset * 2, height: 14)
                .position(x: encCX, y: encT + 59)
        }
    }

    // MARK: - Central Knob

    private var knobView: some View {
        ZStack {
            // Arc track (270° guide, dim white)
            IconArc(startDeg: arcStart, endDeg: arcEnd)
                .stroke(Color.white.opacity(0.09),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .frame(width: arcR * 2, height: arcR * 2)

            // Active arc — blurred glow layer
            IconArc(startDeg: arcStart, endDeg: arcFilled)
                .stroke(amber.opacity(0.52),
                        style: StrokeStyle(lineWidth: 27, lineCap: .round))
                .frame(width: arcR * 2, height: arcR * 2)
                .blur(radius: 16)

            // Active arc — crisp layer
            IconArc(startDeg: arcStart, endDeg: arcFilled)
                .stroke(amber, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .frame(width: arcR * 2, height: arcR * 2)

            // Drop shadow beneath knob body
            Circle()
                .fill(Color.black.opacity(0.65))
                .frame(width: (ringR + 12) * 2, height: (ringR + 12) * 2)
                .blur(radius: 20)
                .offset(y: 14)

            // Outer grip ring — dark machined aluminum
            Circle()
                .fill(LinearGradient(
                    colors: [Color(white: 0.44), Color(white: 0.10)],
                    startPoint: UnitPoint(x: 0.20, y: 0.08),
                    endPoint:   UnitPoint(x: 0.80, y: 0.92)
                ))
                .frame(width: ringR * 2, height: ringR * 2)

            // Diamond knurling texture on grip ring
            IconKnurling(outerR: ringR, innerR: rimR + 4, spacing: 7.5, opacity: 0.40)
                .frame(width: ringR * 2, height: ringR * 2)

            // Inner dome rim — lighter separator edge
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(white: 0.55), Color(white: 0.20)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: rimR * 2, height: rimR * 2)

            // Dome body — raised center with 3D shading
            Circle()
                .fill(RadialGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.38), location: 0.00),
                        .init(color: Color(red: 0.20, green: 0.05, blue: 0.07).opacity(0.90), location: 0.35),
                        .init(color: Color(red: 0.20, green: 0.05, blue: 0.07),               location: 0.65),
                        .init(color: Color(red: 0.20, green: 0.05, blue: 0.07).opacity(0.60), location: 1.00),
                    ],
                    center: UnitPoint(x: 0.30, y: 0.26),
                    startRadius: 0, endRadius: domeR
                ))
                .frame(width: domeR * 2, height: domeR * 2)

            // CNC lathe rings on dome surface
            Canvas { ctx, sz in
                let cx = sz.width / 2, cy = sz.height / 2
                var r: CGFloat = 8
                while r < sz.width / 2 - 1 {
                    var p = Path()
                    p.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
                    ctx.stroke(p, with: .color(Color.white.opacity(0.10)), lineWidth: 1.0)
                    r += 6.5
                }
            }
            .frame(width: domeR * 2, height: domeR * 2)
            .clipShape(Circle())

            // Primary specular (soft, upper-left)
            Ellipse()
                .fill(Color.white.opacity(0.25))
                .frame(width: 52, height: 34)
                .offset(x: -28, y: -31)
                .blur(radius: 7)

            // Hot-spot specular (sharp, tight)
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 14, height: 14)
                .offset(x: -32, y: -35)
                .blur(radius: 3)

            // Recessed indicator groove — rotates with arc position
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black.opacity(0.75))
                    .frame(width: 14, height: 46)
                RoundedRectangle(cornerRadius: 3.5)
                    .fill(amber)
                    .frame(width: 9, height: 40)
                Rectangle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 2.5, height: 36)
                    .offset(x: 2.5)
            }
            .offset(y: -(domeR - 14))
            .rotationEffect(.degrees(arcFilled))
        }
        .position(x: knobX, y: knobY)
    }
}

// MARK: - Arc Shape

private struct IconArc: Shape {
    let startDeg: Double
    let endDeg:   Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center:     CGPoint(x: rect.midX, y: rect.midY),
            radius:     min(rect.width, rect.height) / 2,
            startAngle: .degrees(startDeg - 90),
            endAngle:   .degrees(endDeg   - 90),
            clockwise:  false
        )
        return p
    }
}

// MARK: - Knurling Ring (Canvas diamond crosshatch)

private struct IconKnurling: View {
    let outerR:  CGFloat
    let innerR:  CGFloat
    let spacing: CGFloat
    let opacity: Double

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2, cy = size.height / 2

            // Clip to ring annulus
            var clip = Path()
            clip.addEllipse(in: CGRect(x: cx - outerR, y: cy - outerR,
                                       width: outerR * 2, height: outerR * 2))
            clip.addEllipse(in: CGRect(x: cx - innerR, y: cy - innerR,
                                       width: innerR * 2, height: innerR * 2))
            ctx.clip(to: clip, style: FillStyle(eoFill: true))

            let ext     = outerR + 2
            let shading = GraphicsContext.Shading.color(Color.white.opacity(opacity))

            // +45° lines
            var k: CGFloat = -(ext * 2)
            while k <= ext * 2 {
                var p = Path()
                p.move(to:    CGPoint(x: cx - ext + k, y: cy - ext))
                p.addLine(to: CGPoint(x: cx + ext + k, y: cy + ext))
                ctx.stroke(p, with: shading, lineWidth: 1.8)
                k += spacing
            }

            // −45° lines
            k = -(ext * 2)
            while k <= ext * 2 {
                var p = Path()
                p.move(to:    CGPoint(x: cx + ext - k, y: cy - ext))
                p.addLine(to: CGPoint(x: cx - ext - k, y: cy + ext))
                ctx.stroke(p, with: shading, lineWidth: 1.8)
                k += spacing
            }
        }
    }
}

// MARK: - Preview

#Preview("1024×1024") {
    AppIconView()
        .frame(width: 512, height: 512)
        .scaleEffect(0.5)
        .frame(width: 256, height: 256)
}

#Preview("1024×1024 full") {
    AppIconView()
}
