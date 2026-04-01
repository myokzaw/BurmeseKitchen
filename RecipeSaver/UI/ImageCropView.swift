import SwiftUI

// MARK: - Crop Aspect Ratios
enum CropAspect: String, CaseIterable {
    case hero   = "hero"    // 4:3  — recipe detail screen
    case card   = "card"    // 3:2  — recipe list cards
    case square = "square"  // 1:1  — grid view

    var ratio: CGFloat {
        switch self {
        case .hero:   return 4 / 3
        case .card:   return 3 / 2
        case .square: return 1 / 1
        }
    }

    var label: String {
        switch self {
        case .hero:   return "Detail (4:3)"
        case .card:   return "List (3:2)"
        case .square: return "Grid (1:1)"
        }
    }
}

// MARK: - Rule of Thirds Grid
struct RuleOfThirdsGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Vertical lines
        p.move(to: CGPoint(x: rect.width / 3, y: 0))
        p.addLine(to: CGPoint(x: rect.width / 3, y: rect.height))
        p.move(to: CGPoint(x: rect.width * 2 / 3, y: 0))
        p.addLine(to: CGPoint(x: rect.width * 2 / 3, y: rect.height))
        // Horizontal lines
        p.move(to: CGPoint(x: 0, y: rect.height / 3))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height / 3))
        p.move(to: CGPoint(x: 0, y: rect.height * 2 / 3))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height * 2 / 3))
        return p
    }
}

// MARK: - Image Crop View
// Always presented as .fullScreenCover — it enforces .preferredColorScheme(.dark) internally.
struct ImageCropView: View {
    let image: UIImage
    var onConfirm: (UIImage) -> Void
    var onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedAspect: CropAspect = .hero
    @State private var cropDisplayWidth: CGFloat = 300

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button("Cancel") { onCancel() }
                        .font(.uiMd)
                        .foregroundStyle(Color.white)
                    Spacer()
                    Text("Crop Photo")
                        .font(.bodyBold)
                        .foregroundStyle(Color.white)
                    Spacer()
                    Color.clear
                        .frame(width: 54, height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Crop preview
                GeometryReader { geo in
                    let cropWidth  = geo.size.width - 40
                    let cropHeight = cropWidth / selectedAspect.ratio

                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: cropWidth, height: cropHeight)
                            .scaleEffect(scale)
                            .offset(offset)
                            .clipped()

                        RuleOfThirdsGrid()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            .frame(width: cropWidth, height: cropHeight)

                        Rectangle()
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: cropWidth, height: cropHeight)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { cropDisplayWidth = cropWidth }
                    .onChange(of: cropWidth) { _, newValue in cropDisplayWidth = newValue }
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, min(4.0, lastScale * value))
                                    offset = clampedOffset(for: offset, cropWidth: cropWidth, cropHeight: cropHeight, scale: scale)
                                }
                                .onEnded { _ in
                                    offset = clampedOffset(for: offset, cropWidth: cropWidth, cropHeight: cropHeight, scale: scale)
                                    lastOffset = offset
                                    lastScale = scale
                                },
                            DragGesture()
                                .onChanged { value in
                                    let proposed = CGSize(
                                        width:  lastOffset.width  + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    offset = clampedOffset(for: proposed, cropWidth: cropWidth, cropHeight: cropHeight, scale: scale)
                                }
                                .onEnded { _ in
                                    offset = clampedOffset(for: offset, cropWidth: cropWidth, cropHeight: cropHeight, scale: scale)
                                    lastOffset = offset
                                }
                        )
                    )
                }

                VStack(spacing: 16) {
                    // Aspect ratio picker
                    HStack(spacing: 12) {
                        ForEach(CropAspect.allCases, id: \.self) { aspect in
                            Button(aspect.label) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedAspect = aspect
                                    offset = .zero
                                    lastOffset = .zero
                                    scale = 1.0
                                    lastScale = 1.0
                                }
                            }
                            .font(.uiSm)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedAspect == aspect
                                ? Color.plumMid
                                : Color.white.opacity(0.15))
                            .foregroundStyle(Color.white)
                            .clipShape(Capsule())
                        }
                    }

                    Button(action: cropAndConfirm) {
                        Label("Done", systemImage: "checkmark")
                            .font(.uiMd)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.terra)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func cropAndConfirm() {
        let cropped = cropImage(image, scale: scale, offset: offset, aspect: selectedAspect, displayWidth: cropDisplayWidth)
        onConfirm(cropped)
    }

    private func cropImage(_ source: UIImage, scale: CGFloat, offset: CGSize, aspect: CropAspect, displayWidth: CGFloat) -> UIImage {
        let targetW: CGFloat = 1200
        let targetH: CGFloat = targetW / aspect.ratio
        let cropHeight = displayWidth / aspect.ratio
        let baseScale = max(displayWidth / source.size.width, cropHeight / source.size.height)
        let effectiveScale = baseScale * scale

        let cropRect = CGRect(
            x: ((source.size.width - (displayWidth / effectiveScale)) / 2) - (offset.width / effectiveScale),
            y: ((source.size.height - (cropHeight / effectiveScale)) / 2) - (offset.height / effectiveScale),
            width: displayWidth / effectiveScale,
            height: cropHeight / effectiveScale
        ).standardized

        let boundedCropRect = CGRect(
            x: max(0, min(source.size.width - cropRect.width, cropRect.origin.x)),
            y: max(0, min(source.size.height - cropRect.height, cropRect.origin.y)),
            width: min(source.size.width, cropRect.width),
            height: min(source.size.height, cropRect.height)
        )

        guard let cgImage = source.cgImage?.cropping(to: boundedCropRect.integral) else {
            return source
        }

        UIGraphicsBeginImageContextWithOptions(CGSize(width: targetW, height: targetH), true, 1)
        defer { UIGraphicsEndImageContext() }
        UIImage(cgImage: cgImage).draw(in: CGRect(x: 0, y: 0, width: targetW, height: targetH))
        return UIGraphicsGetImageFromCurrentImageContext() ?? source
    }

    private func clampedOffset(for proposedOffset: CGSize, cropWidth: CGFloat, cropHeight: CGFloat, scale: CGFloat) -> CGSize {
        let baseSize = baseImageSize(cropWidth: cropWidth, cropHeight: cropHeight)
        let scaledWidth = baseSize.width * scale
        let scaledHeight = baseSize.height * scale

        let maxX = max(0, (scaledWidth - cropWidth) / 2)
        let maxY = max(0, (scaledHeight - cropHeight) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -maxX), maxX),
            height: min(max(proposedOffset.height, -maxY), maxY)
        )
    }

    private func baseImageSize(cropWidth: CGFloat, cropHeight: CGFloat) -> CGSize {
        let widthScale = cropWidth / image.size.width
        let heightScale = cropHeight / image.size.height
        let fillScale = max(widthScale, heightScale)

        return CGSize(
            width: image.size.width * fillScale,
            height: image.size.height * fillScale
        )
    }
}
