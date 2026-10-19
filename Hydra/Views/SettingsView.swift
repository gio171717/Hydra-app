import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showDeniedAlert = false
    @State private var confirmReset = false
    @State private var testSent = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    GoalPicker(liters: $store.settings.goalLiters)
                        .padding(.vertical, 8)
                } header: {
                    Text("Obiettivo giornaliero")
                } footer: {
                    Text("Per un adulto si consigliano in genere 1,5–2,5 L al giorno, di più se fa caldo o fai sport.")
                }

                Section {
                    Toggle(isOn: remindersBinding) {
                        Label("Promemoria", systemImage: "bell.fill")
                    }
                    if store.settings.remindersEnabled {
                        DatePicker("Dalle", selection: timeBinding(\.startMinutes), displayedComponents: .hourAndMinute)
                        DatePicker("Alle", selection: timeBinding(\.endMinutes), displayedComponents: .hourAndMinute)
                        Picker("Ogni", selection: $store.settings.intervalMinutes) {
                            ForEach(AppSettings.intervalOptions, id: \.self) { minutes in
                                Text(Fmt.interval(minutes)).tag(minutes)
                            }
                        }
                        Button {
                            Task { @MainActor in
                                await ReminderScheduler.sendTest(settings: store.settings, consumedToday: store.todayTotal)
                                testSent = true
                            }
                        } label: {
                            Label(testSent ? "Inviata: arriverà tra 5 secondi" : "Invia una notifica di prova",
                                  systemImage: testSent ? "checkmark" : "paperplane")
                        }
                    }
                } header: {
                    Text("Promemoria")
                } footer: {
                    Text(reminderSummary)
                }

                Section {
                    ForEach(ContainerKind.allCases) { kind in
                        Stepper(value: containerBinding(kind), in: 50...3000, step: 10) {
                            HStack(spacing: 12) {
                                ContainerIcon(kind: kind, size: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(kind.name)
                                    Text("\(store.settings.ml(for: kind)) ml")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                        }
                    }
                    if !store.settings.containerMl.isEmpty {
                        Button("Ripristina capienze predefinite") {
                            store.settings.containerMl = [:]
                        }
                    }
                } header: {
                    Text("Contenitori")
                } footer: {
                    Text("Imposta la capienza dei tuoi bicchieri e delle tue bottiglie.")
                }

                Section {
                    Button("Azzera la giornata di oggi", role: .destructive) {
                        confirmReset = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
            .alert("Notifiche non consentite", isPresented: $showDeniedAlert) {
                Button("Apri Impostazioni") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("Per ricevere i promemoria consenti le notifiche a Hydra nelle Impostazioni dell'iPhone.")
            }
            .confirmationDialog("Vuoi cancellare tutte le bevute di oggi?",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Azzera oggi", role: .destructive) { store.resetToday() }
            }
        }
    }

    // MARK: - Binding

    private var remindersBinding: Binding<Bool> {
        Binding(
            get: { store.settings.remindersEnabled },
            set: { enabled in
                guard enabled else {
                    store.settings.remindersEnabled = false
                    return
                }
                Task { @MainActor in
                    if await ReminderScheduler.requestAuthorization() {
                        store.settings.remindersEnabled = true
                    } else {
                        showDeniedAlert = true
                    }
                }
            }
        )
    }

    private func timeBinding(_ keyPath: WritableKeyPath<AppSettings, Int>) -> Binding<Date> {
        Binding(
            get: {
                let minutes = store.settings[keyPath: keyPath]
                return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.settings[keyPath: keyPath] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }

    private func containerBinding(_ kind: ContainerKind) -> Binding<Int> {
        Binding(
            get: { store.settings.ml(for: kind) },
            set: { store.settings.containerMl[kind.rawValue] = $0 }
        )
    }

    private var reminderSummary: String {
        let s = store.settings
        guard s.remindersEnabled else {
            return "Attivali per ricevere avvisi durante la giornata con quanto bere per arrivare al tuo obiettivo."
        }
        let count = ReminderScheduler.slotTimes(on: .now, settings: s).count
        guard count > 0 else {
            return "L'orario di fine deve essere successivo a quello di inizio."
        }
        let each = ReminderScheduler.roundToStep(Double(s.goalMl) / Double(count))
        return "\(count) promemoria al giorno dalle \(Fmt.minutesOfDay(s.startMinutes)) alle "
            + "\(Fmt.minutesOfDay(s.endMinutes)), circa \(Fmt.amount(each)) ciascuno. "
            + "Se salti un promemoria, i successivi ti chiederanno un po' di più. "
            + "Tieni premuta una notifica per registrare subito un bicchiere o una bottiglietta."
    }
}

#Preview {
    SettingsView()
        .environment(HydrationStore())
        .preferredColorScheme(.dark)
}
