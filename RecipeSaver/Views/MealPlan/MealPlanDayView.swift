import SwiftUI

struct MealPlanDayView: View {
    @ObservedObject var viewModel: MealPlanViewModel
    @EnvironmentObject var settings: SettingsStore

    let date: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dayName: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE"
        return fmt.string(from: date)
    }

    private var shortDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Day header
            HStack(spacing: 10) {
                Text(dayName)
                    .font(.bodyBold)
                    .foregroundStyle(isToday ? Color.white : Color.primaryText)

                Text(shortDate)
                    .font(.bodySm)
                    .foregroundStyle(isToday ? Color.white.opacity(0.85) : Color.secondaryText)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isToday ? Color.accentTint : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Slot cards
            VStack(spacing: 8) {
                ForEach(MealSlot.allCases, id: \.self) { slot in
                    MealSlotCard(slot: slot, date: date, viewModel: viewModel)
                        .environmentObject(settings)
                }
            }
        }
        .padding(.bottom, 8)
    }
}
