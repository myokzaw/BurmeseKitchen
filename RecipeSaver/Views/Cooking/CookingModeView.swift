import SwiftUI

// MARK: - CookingModeView
// Full-screen hands-free step-by-step cooking experience.
// Presented as .fullScreenCover from RecipeDetailView.
// Keeps the screen on while active via isIdleTimerDisabled.

struct CookingModeView: View {
    let recipe: Recipe
    @State private var currentStep: Int = 0
    @Environment(\.dismiss) private var dismiss

    private var steps: [RecipeStep] { recipe.sortedSteps }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            TabView(selection: $currentStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    CookingStepPage(
                        stepNumber: index + 1,
                        totalSteps: steps.count,
                        stepBody: step.body ?? ""
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Progress dots — bottom centre
            VStack {
                Spacer()
                StepProgressDots(current: currentStep, total: steps.count)
                    .padding(.bottom, 32)
            }

            // Exit button — top left
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.secondaryText)
                            .padding(12)
                            .background(Color.cardFill)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear  { UIApplication.shared.isIdleTimerDisabled = true  }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .preferredColorScheme(nil) // honours system setting
    }
}

// MARK: - CookingStepPage

private struct CookingStepPage: View {
    let stepNumber: Int
    let totalSteps: Int
    let stepBody: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            // Step counter
            Text("Step \(stepNumber) of \(totalSteps)")
                .font(.labelSm)
                .foregroundStyle(Color.tertiaryText)
                .textCase(.uppercase)
                .tracking(1.2)

            // Step body — large serif italic
            Text(stepBody)
                .font(.displayMd)
                .foregroundStyle(Color.primaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Swipe hint — only on first step when more steps exist
            if stepNumber == 1 && totalSteps > 1 {
                HStack {
                    Spacer()
                    Text("Swipe to continue →")
                        .font(.bodySm)
                        .foregroundStyle(Color.tertiaryText)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 80) // clear progress dots
    }
}

// MARK: - StepProgressDots

private struct StepProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.accentTint : Color.divider)
                    .frame(width: i == current ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}
