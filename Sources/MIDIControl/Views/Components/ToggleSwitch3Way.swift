import SwiftUI

/// A horizontal bat-style toggle switch matching real metal guitar pedal toggles.
/// Options are arranged left-to-right; the bat lever slides between positions.
/// Labels appear above each slot.
///
/// Interaction: DragGesture(minimumDistance: 0) on the outer VStack.
/// - onEnded fires for any mouse-down + mouse-up (click or tiny drag).
/// - startLocation.x in .local space maps directly to slot index via x / slotWidth.
/// - .frame(width: trackWidth) constrains the VStack so the local coordinate
///   space is exactly 0 … trackWidth, making the slot calculation reliable.
struct ToggleSwitch3Way: View {
    let parameter: ParameterDefinition
    let options: [ToggleOption]
    @Binding var value: Int
    let onChange: (Int) -> Void
    let theme: PedalColorTheme
    var pedalId: String = ""

    // liveIndex drives the bat position immediately on click via @State re-render.
    // Without this, PedalState (a class) mutations don't propagate to viewModel's
    // objectWillChange, so the parent view doesn't re-render and the bat stays frozen.
    @State private var liveIndex: Int = 0

    private func indexFromValue(_ val: Int) -> Int {
        var bestIndex = 0
        var bestDist = Int.max
        for i in 0..<options.count {
            let dist = abs(options[i].value - val)
            if dist < bestDist { bestDist = dist; bestIndex = i }
        }
        return bestIndex
    }

    private func select(index: Int) {
        liveIndex = index                    // immediate visual update via @State
        let newValue = options[index].value
        value = newValue
        onChange(newValue)
    }

    var body: some View {
        VStack(spacing: 3) {
            // ── Option labels above the switch ──
            HStack(spacing: 0) {
                ForEach(0..<options.count, id: \.self) { i in
                    Text(options[i].name)
                        .font(.system(size: 8, weight: liveIndex == i ? .bold : .regular))
                        .foregroundStyle(
                            liveIndex == i
                                ? theme.labelColor
                                : theme.labelColor.opacity(0.40)
                        )
                        .frame(width: slotWidth)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(width: trackWidth)

            // ── Switch housing (visual only) ──
            ZStack {
                // Housing outer shadow
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black.opacity(0.55))
                    .frame(width: trackWidth + 2, height: trackHeight + 2)
                    .blur(radius: 2)
                    .offset(y: 1.5)

                // Housing body
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(
                        colors: [Color(white: 0.14), Color(white: 0.22)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: trackWidth, height: trackHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(white: 0.42), Color(white: 0.20)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 0.75
                            )
                    )

                // Inner recess / channel
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: trackWidth - 4, height: trackHeight - 3)

                // Position dividers between slots
                HStack(spacing: 0) {
                    ForEach(0..<(options.count - 1), id: \.self) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color(white: 0.32))
                            .frame(width: 1, height: trackHeight * 0.55)
                    }
                    Spacer()
                }
                .frame(width: trackWidth)

                // ── Metal bat lever ──
                batView
                    .offset(x: batOffset)
                    .animation(
                        .interpolatingSpring(mass: 0.25, stiffness: 220, damping: 14),
                        value: liveIndex
                    )
            }
            .frame(width: trackWidth, height: trackHeight)

            // ── Parameter name ──
            Text(parameter.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme.labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: trackWidth)
        }
        // Constrain width so .local coordinate space is exactly 0…trackWidth
        .frame(width: trackWidth)
        .contentShape(Rectangle())
        // DragGesture(minimumDistance:0) fires on any mouse-down + mouse-up.
        // onEnded gives startLocation in .local space → reliable slot calculation.
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded { gesture in
                    // Ignore if the user actually dragged (not a tap)
                    guard abs(gesture.translation.width)  < 10,
                          abs(gesture.translation.height) < 10 else { return }
                    let idx = min(options.count - 1,
                                  max(0, Int(gesture.startLocation.x / slotWidth)))
                    select(index: idx)
                }
        )
        // Sync liveIndex from binding when value changes externally (e.g. preset load)
        .onAppear { liveIndex = indexFromValue(value) }
        .onChange(of: value) { liveIndex = indexFromValue(value) }
        .help(ParameterDescriptions.description(for: parameter.id, cc: parameter.cc, pedalId: pedalId))
    }

    // MARK: - Bat / Lever

    private var batView: some View {
        ZStack {
            // Bat drop shadow
            RoundedRectangle(cornerRadius: 3.5)
                .fill(Color.black.opacity(0.45))
                .frame(width: batWidth + 2, height: batHeight + 2)
                .blur(radius: 1.5)
                .offset(y: 1)

            // Bat body — chrome metallic gradient
            RoundedRectangle(cornerRadius: 3.5)
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color(white: 0.93), location: 0.0),
                        .init(color: Color(white: 0.78), location: 0.40),
                        .init(color: Color(white: 0.60), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: batWidth, height: batHeight)

            // Top specular highlight strip
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.68))
                .frame(width: batWidth * 0.50, height: 2)
                .offset(y: -(batHeight * 0.35))

            // Side sheen line
            Rectangle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 1, height: batHeight * 0.55)
                .offset(x: -(batWidth * 0.28))
        }
    }

    // MARK: - Dimensions

    private var slotWidth:   CGFloat { 26 }
    private var trackWidth:  CGFloat { slotWidth * CGFloat(options.count) }
    private var trackHeight: CGFloat { 18 }
    private var batWidth:    CGFloat { slotWidth - 5 }
    private var batHeight:   CGFloat { trackHeight - 3 }

    private var batOffset: CGFloat {
        let trackCenter = trackWidth / 2
        let slotCenter  = slotWidth * (CGFloat(liveIndex) + 0.5)
        return slotCenter - trackCenter
    }
}
