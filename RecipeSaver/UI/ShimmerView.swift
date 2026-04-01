import SwiftUI

// MARK: - Shimmer Effect
struct ShimmerView: View {
    @State private var isShimmering = false

    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.white.opacity(0), location: 0),
                .init(color: Color.white.opacity(0.5), location: 0.5),
                .init(color: Color.white.opacity(0), location: 1),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .rotationEffect(.degrees(isShimmering ? 45 : -45))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatCount(2)) {
                isShimmering = true
            }
        }
    }
}

// MARK: - Shimmer Modifier
extension View {
    func withShimmer() -> some View {
        self.overlay(
            ShimmerView()
                .blendMode(.screen)
        )
    }
}
