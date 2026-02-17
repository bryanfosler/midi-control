import SwiftUI

/// A row of on/off dip switches
struct DipSwitchBank: View {
    let parameters: [ParameterDefinition]
    let values: Binding<[Int: Int]>
    let onChange: (ParameterDefinition, Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(parameters) { param in
                DipSwitch(
                    label: String(param.name.suffix(2)), // "L1", "R1", etc.
                    isOn: Binding(
                        get: { (values.wrappedValue[param.cc] ?? 0) > 0 },
                        set: { newValue in
                            let ccValue = newValue ? 127 : 0
                            values.wrappedValue[param.cc] = ccValue
                            onChange(param, ccValue)
                        }
                    )
                )
            }
        }
    }
}

/// A single visual dip switch
struct DipSwitch: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isOn ? Color.accentColor : Color.gray.opacity(0.3))
                .frame(width: 24, height: 36)
                .overlay(alignment: isOn ? .top : .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 18, height: 16)
                        .padding(2)
                }
                .onTapGesture {
                    isOn.toggle()
                }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}
