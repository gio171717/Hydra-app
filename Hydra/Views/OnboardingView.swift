import SwiftUI

/// Schermata mostrata al primo avvio: obiettivo e permesso per le notifiche.
struct OnboardingView: View {
    @Environment(HydrationStore.self) private var store
    @State private var liters = 2.0
    @State private var remindersOn = false
    @State private var remindersDenied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.accent, Theme.water], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: Theme.accent.opacity(0.5), radius: 24)
                    .padding(.top, 48)

                VStack(spacing: 10) {
                    Text("Benvenuto in Hydra")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Theme.text)
                    Text("Registra l'acqua che bevi e ricevi promemoria per arrivare al tuo obiettivo ogni giorno.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.muted)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel("Quanta acqua vuoi bere al giorno?")
                    GoalPicker(liters: $liters)
                        .padding(16)
                        .cardStyle()
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel("Promemoria")
                    Button(action: enableReminders) {
                        HStack(spacing: 14) {
                            Image(systemName: remindersOn ? "checkmark.circle.fill" : "bell.badge.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(remindersOn ? "Promemoria attivati" : "Attiva i promemoria")
                                    .font(.headline)
                                    .foregroundStyle(Theme.text)
                                Text(remindersDenied
                                     ? "Notifiche non consentite: puoi attivarle più tardi dalle Impostazioni."
                                     : "Dalle 8:00 alle 22:00, ogni 90 minuti. Puoi cambiarlo quando vuoi.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .cardStyle()
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(remindersOn)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            Button(action: finish) {
                Text("Inizia")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.water))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .background(Theme.background)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear { liters = store.settings.goalLiters }
    }

    private func enableReminders() {
        Task { @MainActor in
            let granted = await ReminderScheduler.requestAuthorization()
            remindersOn = granted
            remindersDenied = !granted
        }
    }

    private func finish() {
        var settings = store.settings
        settings.goalLiters = liters
        settings.remindersEnabled = remindersOn
        settings.hasOnboarded = true
        store.settings = settings
    }
}

#Preview {
    OnboardingView()
        .environment(HydrationStore())
        .preferredColorScheme(.dark)
}
