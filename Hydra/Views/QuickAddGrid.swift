import SwiftUI

/// Griglia con i contenitori standard più il pulsante per l'inserimento manuale.
/// Tieni premuto un contenitore per aggiungerne solo metà o un quarto.
struct QuickAddGrid: View {
    @Environment(HydrationStore.self) private var store
    var onAdd: (ContainerKind, Double) -> Void
    var onCustom: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ContainerKind.allCases) { kind in
                    let ml = store.settings.ml(for: kind)
                    Button { onAdd(kind, 1) } label: {
                        QuickTile(title: kind.shortName, value: Fmt.amount(ml)) {
                            ContainerIcon(kind: kind, size: 38)
                        }
                    }
                    .buttonStyle(PressableStyle())
                    .contextMenu {
                        Button { onAdd(kind, 1) } label: {
                            Label("Intera · \(Fmt.amount(ml))", systemImage: "drop.fill")
                        }
                        Button { onAdd(kind, 0.5) } label: {
                            Label("Metà · \(Fmt.amount(ml / 2))", systemImage: "drop.halffull")
                        }
                        Button { onAdd(kind, 0.25) } label: {
                            Label("Un quarto · \(Fmt.amount(ml / 4))", systemImage: "drop")
                        }
                    }
                    .accessibilityLabel("Aggiungi \(kind.name), \(Fmt.amount(ml))")
                }
            }

            Button(action: onCustom) {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Theme.accent.opacity(0.12)))
                    Text("Inserisci i ml a mano")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .cardStyle()
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Inserisci una quantità a mano")
        }
    }
}

struct QuickTile<Icon: View>: View {
    let title: String
    let value: String
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        VStack(spacing: 8) {
            icon()
                .frame(height: 40)
            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EntryRow: View {
    let entry: DrinkEntry

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let kind = entry.kind {
                    ContainerIcon(kind: kind, size: 28)
                } else {
                    Image(systemName: "drop.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.waterLight)
                }
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.amount(entry.ml))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(entry.sourceName)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            Text(Fmt.time(entry.date))
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cardStyle(cornerRadius: 14)
        .accessibilityElement(children: .combine)
    }
}
