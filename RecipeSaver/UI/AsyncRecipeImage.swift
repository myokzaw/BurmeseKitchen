import SwiftUI

// Loads a recipe cover image off the main thread to prevent scroll jank.
// v3: crop-to-fill with focal point offset — the focal point keeps the
//     subject centred in the frame regardless of the container aspect ratio.
//
// aspect: height = width * aspect (e.g. 3/4 for hero, 2/3 for list, 1/1 for grid)
// focalPoint: CGPoint in [0,1]×[0,1] — from recipe.focalPoint (default 0.5, 0.5)
struct AsyncRecipeImage: View {
    let assetName: String?
    let path: String?
    let aspect: CGFloat
    let focalPoint: CGPoint

    @State private var image: UIImage? = nil
    @State private var imageSize: CGSize = .zero

    init(assetName: String? = nil,
         path: String? = nil,
         aspect: CGFloat,
         focalPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
        self.assetName  = assetName
        self.path       = path
        self.aspect     = aspect
        self.focalPoint = focalPoint
    }

    var body: some View {
        // Color.clear with aspectRatio acts as the sizing anchor —
        // the GeometryReader overlay then reads the resulting frame.
        Color.clear
            .aspectRatio(1 / aspect, contentMode: .fit)
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    Group {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: w, height: h)
                                .offset(x: focalOffsetX(w: w, h: h),
                                        y: focalOffsetY(w: w, h: h))
                                .allowsHitTesting(false)
                        } else if assetName != nil || path != nil {
                            // Still loading — show shimmer
                            ShimmerView()
                                .frame(width: w, height: h)
                        } else {
                            // No image configured — placeholder
                            Color.cardFill
                                .frame(width: w, height: h)
                                .overlay(
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 28, weight: .light))
                                        .foregroundStyle(Color.secondaryText)
                                )
                        }
                    }
                    .frame(width: w, height: h)
                    .clipped()
                }
            )
            .task(id: assetName ?? path) {
                guard assetName != nil || path != nil else { return }
                let loaded = await Task.detached(priority: .userInitiated) {
                    if let assetName {
                        return UIImage(named: assetName)
                    }
                    return ImageStore.load(path: path)
                }.value
                if let loaded {
                    imageSize = loaded.size
                }
                image = loaded
            }
    }

    // MARK: - Focal offset math

    private func focalOffsetX(w: CGFloat, h: CGFloat) -> CGFloat {
        guard imageSize != .zero else { return 0 }
        let scale = max(w / imageSize.width, h / imageSize.height)
        let scaledW = imageSize.width * scale
        let overflow = scaledW - w
        return -(focalPoint.x - 0.5) * overflow
    }

    private func focalOffsetY(w: CGFloat, h: CGFloat) -> CGFloat {
        guard imageSize != .zero else { return 0 }
        let scale = max(w / imageSize.width, h / imageSize.height)
        let scaledH = imageSize.height * scale
        let overflow = scaledH - h
        return -(focalPoint.y - 0.5) * overflow
    }
}
