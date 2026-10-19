import SwiftUI

/// Inserimento manuale dei millilitri bevuti.
struct CustomAmountSheet: View {
    var onAdd: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    private static let maxMl = 5000
    private let presets = [100, 150, 330, 400, 750]

    private var value: Int { Int(text) ?? 0 }
    private var isValid: Bool { value > 0 && value <= Self.maxMl }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("0", text: $text)
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .fixedSize()
                        .foregroundStyle(Theme.text)
                    Text("ml")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Theme.muted)
                }
                .onTapGesture { focused = true }

                HStack(spacing: 16) {
                    stepButton(systemImage: "minus", delta: -50)
                    Text("50 ml")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                    stepButton(systemImage: "plus", delta: 50)
                }

                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { ml in
                        Button { text = String(ml) } label: {
                            Text("\(ml)")
                                .font(.subheadline.weight(.medium))
                                .monospacedDigit()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .cardStyle(cornerRadius: 12)
                        }
                        .buttonStyle(PressableStyle())
                        .foregroundStyle(value == ml ? Theme.accent : Theme.text)
                    }
                }

                if value > Self.maxMl {
                    Text("Massimo \(Fmt.liters(Self.maxMl)) per volta")
                        .font(.caption)
                        .foregroundStyle(Theme.danger)
                }

                Spacer(minLength: 0)

                Button {
                    onAdd(value)
                    dismiss()
                } label: {
                    Text(isValid ? "Aggiungi \(Fmt.amount(value))" : "Aggiungi")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isValid ? Theme.water : Theme.card)
                        )
                        .foregroundStyle(isValid ? .white : Theme.muted)
                }
                .buttonStyle(PressableStyle())
                .disabled(!isValid)
            }
            .padding(20)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Quantità manuale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
            .onChange(of: text) { _, newValue in
                let digits = String(newValue.filter(\.isNumber).prefix(4))
                if digits != newValue { text = digits }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.large])
    }

    private func stepButton(systemImage: String, delta: Int) -> some View {
        Button {
            let newValue = min(max(value + delta, 0), Self.maxMl)
            text = newValue == 0 ? "" : String(newValue)
        } label: {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.card))
                .overlay(Circle().strokeBorder(Theme.border))
        }
        .buttonStyle(PressableStyle())
        .foregroundStyle(Theme.accent)
    }
}

#Preview {
    CustomAmountSheet { _ in }
        .preferredColorScheme(.dark)
}
