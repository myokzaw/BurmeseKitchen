import SwiftUI

// MARK: - Bottom Toast Notification
struct ToastNotification: View {
    let title: String
    let message: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.uiMd)
                        .foregroundStyle(Color.primaryText)

                    Text(message)
                        .font(.bodySm)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ToastContainer<Content: View>: View {
    @State private var isShowing = false
    let content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            if isShowing {
                VStack {
                    Spacer()
                    ToastNotification(
                        title: "Saved to My Recipes",
                        message: "Recipe is ready to edit.",
                        icon: "checkmark.circle.fill",
                        accent: .foliage
                    )
                    .padding(16)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                }
            }
        }
    }
}
