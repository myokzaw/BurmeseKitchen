import Combine
import SwiftUI

// MARK: - FloatingBanner data model

struct FloatingBanner {
    let id: UUID
    let title: String           // bold top line, e.g. "Recipe deleted"
    let subtitle: String        // dim bottom line, e.g. "Tap Undo to restore"
    let icon: String            // SF symbol for the left circle
    let accentColor: Color      // icon tint + action label colour
    let actionLabel: String?    // e.g. "Undo", "View" — nil = no action, only ✕
    let duration: Double        // seconds until auto-dismiss
    let onAction: (() -> Void)? // called if actionLabel tapped
    let onDismiss: (() -> Void)?// called only on timeout, NOT on ✕ tap
}

extension FloatingBanner: Equatable {
    static func == (lhs: FloatingBanner, rhs: FloatingBanner) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - BannerManager

class BannerManager: ObservableObject {
    static let shared = BannerManager()
    @Published var current: FloatingBanner? = nil
    private var dismissTask: Task<Void, Never>? = nil

    private init() {}

    func show(_ banner: FloatingBanner) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            current = banner
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(banner.duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            banner.onDismiss?()
            dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            current = nil
        }
    }

    /// Tap-dismiss: cancels timer, no onDismiss side-effect.
    func dismissImmediate() {
        dismiss()
    }

    /// Action-tap: cancels timer, fires onAction, dismisses.
    func triggerAction() {
        dismissTask?.cancel()
        let action = current?.onAction
        withAnimation(.easeInOut(duration: 0.25)) {
            current = nil
        }
        action?()
    }
}

// MARK: - FloatingBannerView

struct FloatingBannerView: View {
    let banner: FloatingBanner
    @ObservedObject var manager: BannerManager

    var body: some View {
        HStack(spacing: 12) {
            // Left icon circle
            ZStack {
                Circle()
                    .fill(Color.appBackground.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: banner.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(banner.accentColor)
            }

            // Text stack
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.bodyBold)
                    .foregroundStyle(Color.appBackground)
                    .lineLimit(1)
                Text(banner.subtitle)
                    .font(.bodySm)
                    .foregroundStyle(Color.appBackground.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()

            // Right: optional action label + ✕ dismiss
            HStack(spacing: 12) {
                if banner.actionLabel != nil {
                    Button(banner.actionLabel!) {
                        manager.triggerAction()
                    }
                    .font(.bodyBold)
                    .foregroundStyle(banner.accentColor)
                }

                Button {
                    manager.dismissImmediate()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appBackground.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.primaryText)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.accentTint.opacity(0.25), radius: 20, x: 0, y: 8)
    }
}
