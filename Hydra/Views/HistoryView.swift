import Charts
import SwiftUI

struct HistoryView: View {
    @Environment(HydrationStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var week: [DailyTotal] { store.dailyTotals(days: 7) }

    var body: some View {
        let days = week
        let goal = store.goalMl
        let average = days.isEmpty ? 0 : days.reduce(0) { $0 + $1.ml } / days.count
        let reached = days.filter { $0.ml >= goal }.count

        NavigationStack {
            List {
                Section {
                    chart(days: days, goal: goal)
                        .frame(height: 200)
                        .padding(.vertical, 8)
                } header: {
                    Text("Ultimi 7 giorni")
                }

                Section {
                    HStack(spacing: 12) {
                        stat(title: "Media", value: Fmt.liters(average))
                        stat(title: "Obiettivo raggiunto", value: "\(reached)/7 giorni")
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Giorni") {
                    ForEach(days.reversed()) { day in
                        HStack {
                            Text(dayLabel(day.day))
                            Spacer()
                            Text(Fmt.liters(day.ml))
                                .monospacedDigit()
                                .foregroundStyle(day.ml >= goal ? Theme.accent : Theme.text)
                            ProgressView(value: min(1, goal > 0 ? Double(day.ml) / Double(goal) : 0))
                                .tint(day.ml >= goal ? Theme.accent : Theme.water)
                                .frame(width: 60)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Storico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
    }

    private func chart(days: [DailyTotal], goal: Int) -> some View {
        Chart {
            ForEach(days) { day in
                BarMark(
                    x: .value("Giorno", day.day, unit: .day),
                    y: .value("Litri", Double(day.ml) / 1000)
                )
                .foregroundStyle(day.ml >= goal ? Theme.accent : Theme.water)
                .cornerRadius(6)
            }
            RuleMark(y: .value("Obiettivo", Double(goal) / 1000))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Theme.muted)
                .annotation(position: .top, alignment: .leading) {
                    Text("Obiettivo \(Fmt.liters(goal))")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated).locale(Fmt.locale), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Theme.border)
                AxisValueLabel {
                    if let liters = value.as(Double.self) {
                        Text(liters.formatted(.number.precision(.fractionLength(0...1)).locale(Fmt.locale)) + " L")
                    }
                }
            }
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle(cornerRadius: 14)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Oggi" }
        if cal.isDateInYesterday(date) { return "Ieri" }
        return date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(Fmt.locale)).capitalized
    }
}

#Preview {
    HistoryView()
        .environment(HydrationStore())
        .preferredColorScheme(.dark)
}
