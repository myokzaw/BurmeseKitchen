import SwiftUI

struct MeasurementConverterView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [BurmeseMeasurement] {
        if searchText.isEmpty { return burmeseMeasurements }
        return burmeseMeasurements.filter {
            $0.informal.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Measurement\nConverter")
                            .font(.displayMd)
                            .foregroundStyle(Color.primaryText)

                        Text("Traditional Burmese units → standard")
                            .font(.bodySm)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.tertiaryText)
                        TextField("Search measurements", text: $searchText)
                            .font(.body)
                            .foregroundStyle(Color.primaryText)
                    }
                    .padding(12)
                    .background(Color.inputFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Measurement rows
                    VStack(spacing: 14) {
                        ForEach(filtered) { measurement in
                            measurementRow(measurement)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.uiMd)
                        .foregroundStyle(Color.accentTint)
                }
            }
        }
    }

    @ViewBuilder
    private func measurementRow(_ m: BurmeseMeasurement) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Left: informal name + Myanmar script
            VStack(alignment: .leading, spacing: 3) {
                Text(m.informal)
                    .font(.bodyBold)
                    .foregroundStyle(Color.primaryText)

                if settings.showBurmese, let burmese = m.burmese {
                    Text(burmese)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondaryText)
                        .lineSpacing(4)
                }
            }

            Spacer()

            // Right: standard value
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Text(formatValue(m.standardValue))
                        .font(.bodyBold)
                        .foregroundStyle(Color.foliage)
                    Text(m.standardUnit)
                        .font(.body)
                        .foregroundStyle(Color.foliage)
                }
                Text(m.notes)
                    .font(.bodySm)
                    .foregroundStyle(Color.tertiaryText)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 160)
            }
        }
        .padding(14)
        .background(Color.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
