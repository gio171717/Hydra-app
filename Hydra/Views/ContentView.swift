import SwiftUI

struct ContentView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    @State private var sheet: ActiveSheet?
    @State private var lastAdded: DrinkEntry?

    enum ActiveSheet: String, Identifiable {
        case custom, settings, history
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                Text(store.today.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Fmt.locale)).capitalized)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .plainRow(top: 0)

                gaugeSection.plainRow(top: 8)

                SectionLabel("Aggiungi").plainRow(top: 22)
                QuickAddGrid(
                    onAdd: { kind, fraction in add { store.add(kind, fraction: fraction) } },
                    onCustom: { sheet = .custom }
                )
                .plainRow()

                HStack {
                    SectionLabel("Oggi")
                    Spacer()
                    if !store.todayEntries.isEmpty {
                        Text(store.todayEntries.count == 1 ? "1 bevuta" : "\(store.todayEntries.count) bevute")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .plainRow(top: 22)

                if store.todayEntries.isEmpty {
                    emptyState.plainRow()
                } else {
                    ForEach(store.todayEntries) { entry in
                        EntryRow(entry: entry)
                            .plainRow(top: 4, bottom: 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { store.delete(entry) }
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                    }
                    Text("Scorri a sinistra su una bevuta per eliminarla")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .plainRow(top: 6, bottom: 40)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    Theme.background
                    Theme.backgroundGradient
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Hydra")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .history } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                    .accessibilityLabel("Storico")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .settings } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Impostazioni")
                }
            }
            .safeAreaInset(edge: .bottom) { undoToast }
        }
        .sheet(item: $sheet) { sheet in
            Group {
                switch sheet {
                case .custom:
                    CustomAmountSheet { ml in add { store.add(ml: ml, kind: nil) } }
                case .settings:
                    SettingsView()
                case .history:
                    HistoryView()
                }
            }
            .environment(store)
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: store.todayTotal) { old, new in new > old }
        .sensoryFeedback(.success, trigger: store.goalReached) { old, new in !old && new }
    }

    // MARK: - Sezioni

    private var gaugeSection: some View {
        VStack(spacing: 18) {
            WaterGauge(total: store.todayTotal, goal: store.goalMl)
                .padding(.top, 12)

            VStack(spacing: 10) {
                if store.goalReached {
                    Label("Obiettivo raggiunto!", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Theme.accent.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.3)))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Ti mancano \(Text(Fmt.amount(store.remainingMl)).foregroundStyle(Theme.text).bold())")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }

                if let next = store.nextReminder {
                    Label("Prossimo promemoria alle \(Fmt.time(next.date)) · circa \(Fmt.amount(next.ml))",
                          systemImage: "bell")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                } else if !store.settings.remindersEnabled {
                    Button { sheet = .settings } label: {
                        Label("Attiva i promemoria", systemImage: "bell.badge")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(PressableStyle())
                    .foregroundStyle(Theme.accent)
                }
            }
            .animation(.spring, value: store.goalReached)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "drop")
                .font(.system(size: 30))
                .foregroundStyle(Theme.muted.opacity(0.6))
            Text("Nessuna bevuta registrata oggi")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private var undoToast: some View {
        if let entry = lastAdded {
            HStack(spacing: 10) {
                Image(systemName: "drop.fill").foregroundStyle(Theme.accent)
                Text("+\(Fmt.amount(entry.ml))").font(.subheadline.weight(.semibold))
                Text(entry.sourceName)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button("Annulla") {
                    withAnimation(.spring) {
                        store.delete(entry)
                        lastAdded = nil
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.border))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: entry.id) {
                do {
                    try await Task.sleep(for: .seconds(3))
                    withAnimation(.spring) { lastAdded = nil }
                } catch {}
            }
        }
    }

    // MARK: - Helpers

    private func add(_ action: () -> DrinkEntry?) {
        withAnimation(.spring) {
            lastAdded = action()
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !store.settings.hasOnboarded },
            set: { presented in if !presented { store.settings.hasOnboarded = true } }
        )
    }
}

extension View {
    /// Riga di lista "trasparente", senza separatori, con i margini dell'app.
    func plainRow(top: CGFloat = 6, bottom: CGFloat = 6) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: 20, bottom: bottom, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

#Preview {
    ContentView()
        .environment(HydrationStore())
        .preferredColorScheme(.dark)
}
