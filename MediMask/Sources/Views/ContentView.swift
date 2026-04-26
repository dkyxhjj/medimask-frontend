import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

private enum ProcessingState {
    case idle
    case photoSelected(UIImage)
    case processing(UIImage)
    case done(original: UIImage, blurred: UIImage)
}

struct ContentView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var state: ProcessingState = .idle
    @State private var saveConfirmation = false

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    mainCard
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                }
            }
        }
    }

    // MARK: - Main card

    private var mainCard: some View {
        VStack(spacing: 24) {
            logoSection
            Divider().background(Color.white.opacity(0.15))
            contentArea
            actionButton
            tagline
        }
        .padding(24)
        .dashedBorder(cornerRadius: 20, color: .white.opacity(0.35))
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.65), lineWidth: 1.5)
                    .frame(width: 72, height: 72)
                Image(systemName: "eye.slash")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
            }
            Text("MediMask")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Content area switches on state

    @ViewBuilder
    private var contentArea: some View {
        switch state {
        case .idle:
            uploadArea(preview: nil)
        case .photoSelected(let img):
            uploadArea(preview: img)
        case .processing(let img):
            processingArea(img)
        case .done(_, let blurred):
            resultArea(blurred)
        }
    }

    // MARK: - Upload area

    private func uploadArea(preview: UIImage?) -> some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))

                VStack(spacing: 12) {
                    if let img = preview {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text("tap to change photo")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    } else {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 42, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Upload Medical Image")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                        Text("tap to select from your library")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.vertical, 36)
                .padding(.horizontal, 20)
            }
            .dashedBorder(cornerRadius: 14, color: .white.opacity(0.35))
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let img = UIImage(data: data) else { return }
                state = .photoSelected(img)
            }
        }
    }

    // MARK: - Processing area

    private func processingArea(_ img: UIImage) -> some View {
        ZStack {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .blur(radius: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.45))
                )

            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                Text("Analyzing & masking…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(minHeight: 200)
    }

    // MARK: - Result area

    private func resultArea(_ img: UIImage) -> some View {
        VStack(spacing: 14) {
            HStack {
                Label("Protected", systemImage: "checkmark.shield.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.45, green: 0.85, blue: 0.6))
                Spacer()
                if saveConfirmation {
                    Text("Saved")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .transition(.opacity)
                }
            }

            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Button {
                    state = .idle
                    photoItem = nil
                } label: {
                    Label("New Photo", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }

                Button {
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    withAnimation { saveConfirmation = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { saveConfirmation = false }
                    }
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(red: 0.97, green: 0.96, blue: 0.93))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
            }
        }
    }

    // MARK: - Action button

    private var actionButton: some View {
        Button {
            handleBlurTap()
        } label: {
            Text(buttonLabel)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!buttonEnabled)
    }

    private var buttonLabel: String {
        switch state {
        case .done: return "Blur Again"
        default: return "Blur Photo"
        }
    }

    private var buttonEnabled: Bool {
        switch state {
        case .idle, .processing: return false
        default: return true
        }
    }

    private var buttonBackground: Color {
        buttonEnabled
            ? Color(red: 0.97, green: 0.96, blue: 0.93)
            : Color.white.opacity(0.15)
    }

    // MARK: - Tagline

    private var tagline: some View {
        Text("protect patient privacy.\nblur faces & identifying info.")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.45))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
    }

    // MARK: - Processing

    private func handleBlurTap() {
        let source: UIImage
        switch state {
        case .photoSelected(let img): source = img
        case .done(let original, _): source = original
        default: return
        }
        state = .processing(source)
        Task.detached(priority: .userInitiated) {
            let result = await blurImage(source)
            await MainActor.run {
                if let result {
                    state = .done(original: source, blurred: result)
                } else {
                    state = .photoSelected(source)
                }
            }
        }
    }

    private func blurImage(_ image: UIImage) async -> UIImage? {
        guard let ci = CIImage(image: image) else { return nil }
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ci
        filter.radius = 22
        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Dashed border modifier

private struct DashedBorder: ViewModifier {
    let cornerRadius: CGFloat
    let color: Color

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .foregroundColor(color)
        )
    }
}

private extension View {
    func dashedBorder(cornerRadius: CGFloat, color: Color) -> some View {
        modifier(DashedBorder(cornerRadius: cornerRadius, color: color))
    }
}

#Preview {
    ContentView()
}
