import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var showConverter = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Settings")
                            .font(.displayMd)
                            .foregroundStyle(Color.primaryText)

                        Text("Burmese Kitchen")
                            .font(.labelSm)
                            .foregroundStyle(Color.tertiaryText)
                            .tracking(1.5)
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                    // MARK: - Language section
                    sectionHeader("Language")

                    settingsCard {
                        Toggle(isOn: $settings.showBurmese) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show Burmese Script")
                                    .font(.bodyBold)
                                    .foregroundStyle(Color.primaryText)
                                Text("မုန့်ဟင်းခါး · ရှမ်းခေါက်ဆွဲ")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.secondaryText)
                                    .lineSpacing(4)
                            }
                        }
                        .tint(Color.accentTint)
                    }
                    .padding(.horizontal, 20)

                    Text("Displays Myanmar script titles and ingredient names alongside English on built-in Burmese recipes.")
                        .font(.bodySm)
                        .foregroundStyle(Color.tertiaryText)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // MARK: - Converter section
                    sectionHeader("Reference")

                    settingsCard {
                        Button {
                            showConverter = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Measurement Converter")
                                        .font(.bodyBold)
                                        .foregroundStyle(Color.primaryText)
                                    Text("Informal Burmese units → standard")
                                        .font(.bodySm)
                                        .foregroundStyle(Color.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.uiSm)
                                    .foregroundStyle(Color.tertiaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - About section
                    sectionHeader("About")

                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            infoRow(label: "App", value: "Burmese Kitchen")
                            Divider().background(Color.divider)
                            infoRow(label: "Version", value: "2.0")
                            Divider().background(Color.divider)
                            infoRow(label: "Recipes", value: "Expanded Burmese recipe library")
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.appBackground)
            .sheet(isPresented: $showConverter) {
                MeasurementConverterView()
                    .environmentObject(settings)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.labelXs)
            .foregroundStyle(Color.tertiaryText)
            .tracking(1.5)
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(Color.secondaryText)
            Spacer()
            Text(value)
                .font(.bodyBold)
                .foregroundStyle(Color.primaryText)
        }
    }
}
