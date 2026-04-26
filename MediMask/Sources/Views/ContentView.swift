import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

private enum ProcessingState {
    case idle
    case photoSelected(UIImage)
    case processing(UIImage)
}

private struct ResultData: Identifiable {
    let id = UUID()
    let original: UIImage
    let blurred: UIImage
}

struct ContentView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var state: ProcessingState = .idle
    @State private var resultData: ResultData?
    @State private var appearAnimation = false
    @State private var breathe = false
    @State private var scanLineOffset: CGFloat = 0
    @State private var buttonPressed = false
    @State private var orbPhase: CGFloat = 0
    @State private var ringRotation: Double = 0
    @State private var particlePhase: CGFloat = 0

    private let accentBlue = Color(red: 0.29, green: 0.42, blue: 0.97)
    private let accentPurple = Color(red: 0.48, green: 0.32, blue: 0.95)
    private let accentCyan = Color(red: 0.25, green: 0.65, blue: 0.96)
    private let bgDark = Color(red: 0.06, green: 0.07, blue: 0.16)
    private let bgMid = Color(red: 0.10, green: 0.11, blue: 0.22)

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [bgDark, bgMid, bgDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Living background orbs
            backgroundOrbs

            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    headerSection
                    contentArea
                    actionButton
                    tagline
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(item: $resultData) { data in
            ResultView(
                originalImage: data.original,
                blurredImage: data.blurred,
                onDismiss: {
                    resultData = nil
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        state = .idle
                        photoItem = nil
                    }
                }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                appearAnimation = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                orbPhase = 1
            }
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                particlePhase = 1
            }
        }
    }

    // MARK: - Background

    private var backgroundOrbs: some View {
        GeometryReader { geo in
            // Large primary orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentBlue.opacity(0.15), .clear],
                        center: .center, startRadius: 0, endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .position(
                    x: geo.size.width * 0.7 + sin(orbPhase * .pi * 2) * 40,
                    y: geo.size.height * 0.15 + cos(orbPhase * .pi * 2) * 25
                )
                .blur(radius: 60)

            // Purple orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentPurple.opacity(0.1), .clear],
                        center: .center, startRadius: 0, endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .position(
                    x: geo.size.width * 0.2 + cos(orbPhase * .pi * 2 + 2) * 35,
                    y: geo.size.height * 0.6 + sin(orbPhase * .pi * 2 + 2) * 30
                )
                .blur(radius: 50)

            // Cyan accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentCyan.opacity(0.08), .clear],
                        center: .center, startRadius: 0, endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .position(
                    x: geo.size.width * 0.5 + sin(orbPhase * .pi * 2 + 4) * 30,
                    y: geo.size.height * 0.85 + cos(orbPhase * .pi * 2 + 4) * 20
                )
                .blur(radius: 40)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Floating logo with animated rings
            ZStack {
                // Outer rotating ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                accentBlue.opacity(0.3),
                                accentPurple.opacity(0.15),
                                accentCyan.opacity(0.3),
                                accentBlue.opacity(0.05),
                                accentBlue.opacity(0.3)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(ringRotation))

                // Breathing glow
                Circle()
                    .fill(accentBlue.opacity(breathe ? 0.12 : 0.04))
                    .frame(width: 68, height: 68)
                    .blur(radius: 8)

                // Icon
                Image(systemName: "eye.slash")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentCyan, accentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 6) {
                Text("MediMask")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("PRIVACY SHIELD")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(5)
                    .foregroundColor(accentCyan.opacity(0.5))
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : -30)
    }

    // MARK: - Content area

    @ViewBuilder
    private var contentArea: some View {
        switch state {
        case .idle:
            uploadArea(preview: nil)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
        case .photoSelected(let img):
            uploadArea(preview: img)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
        case .processing(let img):
            processingArea(img)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Upload area (no box)

    private func uploadArea(preview: UIImage?) -> some View {
        VStack(spacing: 24) {
            if let img = preview {
                // Selected image — not wrapped in picker
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [accentBlue.opacity(0.4), accentPurple.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: accentBlue.opacity(0.2), radius: 30, y: 10)

                // Separate small change-photo button
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("change photo")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(accentCyan.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                }
            } else {
                // Floating upload invitation — picker only here
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 28) {
                        ZStack {
                            Circle()
                                .stroke(accentBlue.opacity(breathe ? 0.15 : 0.05), lineWidth: 1)
                                .frame(width: 120, height: 120)
                                .scaleEffect(breathe ? 1.1 : 0.95)

                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [accentCyan.opacity(0.3), accentPurple.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: 96, height: 96)

                            Circle()
                                .fill(accentBlue.opacity(breathe ? 0.1 : 0.04))
                                .frame(width: 72, height: 72)
                                .blur(radius: 10)

                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [accentCyan, accentBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(spacing: 8) {
                            Text("Upload Medical Image")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))

                            Text("tap to select from your library")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.35))
                        }

                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(accentBlue.opacity(0.3))
                                    .frame(width: 4, height: 4)
                                    .offset(y: breathe ? -3 : 3)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.2),
                                        value: breathe
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let img = UIImage(data: data) else { return }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    state = .photoSelected(img)
                }
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Processing area

    private func processingArea(_ img: UIImage) -> some View {
        VStack(spacing: 24) {
            // Image with scan effect
            ZStack {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .blur(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(bgDark.opacity(0.4))
                    )
                    .overlay(
                        // Scanning beam
                        GeometryReader { geo in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, accentCyan.opacity(0.35), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 50)
                                .offset(y: scanLineOffset * geo.size.height)
                                .blur(radius: 6)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(accentCyan.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: accentCyan.opacity(0.1), radius: 25, y: 8)

                // Floating status pill
                VStack(spacing: 14) {
                    // Spinner
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 2.5)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(
                                LinearGradient(
                                    colors: [accentCyan, accentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(Double(scanLineOffset) * 1080))
                    }

                    Text("Analyzing & masking")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))

                    // Animated dots
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(accentCyan)
                                .frame(width: 5, height: 5)
                                .opacity(Double(scanLineOffset) > Double(i) * 0.3 ? 0.8 : 0.2)
                        }
                    }
                }
            }
        }
        .onAppear {
            scanLineOffset = 0
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                scanLineOffset = 1
            }
        }
    }

    // MARK: - Action button

    private var actionButton: some View {
        Button {
            buttonPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                buttonPressed = false
            }
            handleBlurTap()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 18, weight: .semibold))
                Text(buttonLabel)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(buttonEnabled ? .white : .white.opacity(0.2))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                Group {
                    if buttonEnabled {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentBlue, accentPurple.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.18), .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            )
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                }
            )
            .clipShape(Capsule())
        }
        .disabled(!buttonEnabled)
        .scaleEffect(buttonPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: buttonPressed)
        .shadow(color: buttonEnabled ? accentBlue.opacity(0.25) : .clear, radius: 20, y: 8)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var buttonLabel: String { "Blur Photo" }
    private var buttonIcon: String { "wand.and.stars" }

    private var buttonEnabled: Bool {
        switch state {
        case .photoSelected: return true
        default: return false
        }
    }

    // MARK: - Tagline

    private var tagline: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accentBlue.opacity(0.3))
                .frame(width: 4, height: 4)
            Text("end-to-end privacy protection")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.2))
            Circle()
                .fill(accentBlue.opacity(0.3))
                .frame(width: 4, height: 4)
        }
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Processing logic

    private func handleBlurTap() {
        guard case .photoSelected(let source) = state else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            state = .processing(source)
        }
        Task.detached(priority: .userInitiated) {
            let result = await blurImage(source)
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    state = .photoSelected(source)
                }
                if let result {
                    resultData = ResultData(original: source, blurred: result)
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

#Preview {
    ContentView()
}
