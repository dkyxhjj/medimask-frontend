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
    @State private var snowPhase: CGFloat = 0
    @State private var ringRotation: Double = 0
    @State private var frostBreath: Bool = false

    // ICE palette
    private let iceTeal = Color(red: 0.31, green: 0.69, blue: 0.72)
    private let iceLight = Color(red: 0.55, green: 0.82, blue: 0.85)
    private let iceDark = Color(red: 0.05, green: 0.12, blue: 0.15)
    private let iceMid = Color(red: 0.08, green: 0.18, blue: 0.22)
    private let frostWhite = Color(red: 0.85, green: 0.95, blue: 0.97)

    var body: some View {
        ZStack {
            // Frozen gradient
            LinearGradient(
                colors: [iceDark, iceMid, iceDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Snow particles
            snowfall

            // Frost mist
            frostMist

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
                snowPhase = 1
            }
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                frostBreath = true
            }
        }
    }

    // MARK: - Snow

    private var snowfall: some View {
        GeometryReader { geo in
            ForEach(0..<15, id: \.self) { i in
                let seed = Double(i) * 1.618
                let x = seed.truncatingRemainder(dividingBy: 1.0)
                let speed = 0.25 + Double(i % 4) * 0.12
                let size = CGFloat(1 + i % 3)
                Circle()
                    .fill(frostWhite.opacity(speed * 0.4))
                    .frame(width: size, height: size)
                    .position(
                        x: geo.size.width * CGFloat(x) + sin(Double(snowPhase) * .pi * 2 + seed * 3) * 12,
                        y: geo.size.height * CGFloat(
                            (Double(snowPhase) * speed + seed).truncatingRemainder(dividingBy: 1.0)
                        )
                    )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Frost mist

    private var frostMist: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [iceTeal.opacity(0.12), .clear],
                        center: .center, startRadius: 0, endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 80, y: -60)
                .blur(radius: 60)
                .opacity(frostBreath ? 0.8 : 0.3)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [iceLight.opacity(0.08), .clear],
                        center: .center, startRadius: 0, endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -60, y: 200)
                .blur(radius: 50)
                .opacity(frostBreath ? 0.6 : 0.2)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Frost ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                iceTeal.opacity(0.3),
                                iceLight.opacity(0.15),
                                frostWhite.opacity(0.25),
                                iceTeal.opacity(0.05),
                                iceTeal.opacity(0.3)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(ringRotation))

                Circle()
                    .fill(iceTeal.opacity(breathe ? 0.12 : 0.04))
                    .frame(width: 68, height: 68)
                    .blur(radius: 8)

                Image(systemName: "eye.slash")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [frostWhite, iceTeal],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("MEDIMASK")
                    .font(.system(size: 30, weight: .heavy, design: .default).width(.compressed))
                    .scaleEffect(x: 0.75, y: 1.4)
                    .tracking(2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [frostWhite, iceTeal, iceLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("S U B · Z E R O")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(3)
                    .foregroundColor(iceTeal.opacity(0.5))
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

    // MARK: - Upload

    private func uploadArea(preview: UIImage?) -> some View {
        VStack(spacing: 24) {
            if let img = preview {
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
                                    colors: [frostWhite.opacity(0.3), iceTeal.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: iceTeal.opacity(0.15), radius: 30, y: 10)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text("change photo")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(iceLight.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(frostWhite.opacity(0.06)))
                    .overlay(Capsule().strokeBorder(frostWhite.opacity(0.08), lineWidth: 1))
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 28) {
                        ZStack {
                            // Ice crystal rings
                            Circle()
                                .stroke(iceTeal.opacity(breathe ? 0.2 : 0.06), lineWidth: 1)
                                .frame(width: 120, height: 120)
                                .scaleEffect(breathe ? 1.1 : 0.95)

                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [frostWhite.opacity(0.25), iceTeal.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: 96, height: 96)

                            Circle()
                                .fill(iceTeal.opacity(breathe ? 0.1 : 0.04))
                                .frame(width: 72, height: 72)
                                .blur(radius: 10)

                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [frostWhite, iceTeal],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }

                        VStack(spacing: 8) {
                            Text("Upload Medical Image")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(frostWhite.opacity(0.9))

                            Text("tap to select from your library")
                                .font(.system(size: 14))
                                .foregroundColor(frostWhite.opacity(0.3))
                        }

                        // Ice crystal dots
                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(iceTeal.opacity(0.4))
                                    .frame(width: 2, height: breathe ? 8 : 4)
                                    .animation(
                                        .easeInOut(duration: 1.2)
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

    // MARK: - Processing

    private func processingArea(_ img: UIImage) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .blur(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(iceDark.opacity(0.4))
                    )
                    .overlay(
                        GeometryReader { geo in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, frostWhite.opacity(0.25), .clear],
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
                            .strokeBorder(iceTeal.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: iceTeal.opacity(0.1), radius: 25, y: 8)

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(frostWhite.opacity(0.06), lineWidth: 2.5)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(
                                LinearGradient(
                                    colors: [frostWhite, iceTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(Double(scanLineOffset) * 1080))
                    }

                    Text("Freezing data")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(frostWhite.opacity(0.9))

                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(iceTeal)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { buttonPressed = false }
            handleBlurTap()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .semibold))
                Text("Blur Photo")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(buttonEnabled ? iceDark : frostWhite.opacity(0.2))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                Group {
                    if buttonEnabled {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [iceTeal, iceLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [frostWhite.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            )
                    } else {
                        Capsule()
                            .fill(frostWhite.opacity(0.04))
                            .overlay(
                                Capsule().strokeBorder(frostWhite.opacity(0.06), lineWidth: 1)
                            )
                    }
                }
            )
            .clipShape(Capsule())
        }
        .disabled(!buttonEnabled)
        .scaleEffect(buttonPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: buttonPressed)
        .shadow(color: buttonEnabled ? iceTeal.opacity(0.3) : .clear, radius: 20, y: 8)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private var buttonEnabled: Bool {
        if case .photoSelected = state { return true }
        return false
    }

    // MARK: - Tagline

    private var tagline: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1)
                .fill(iceTeal.opacity(0.3))
                .frame(width: 12, height: 1)
            Text("freeze the noise")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(frostWhite.opacity(0.2))
            RoundedRectangle(cornerRadius: 1)
                .fill(iceTeal.opacity(0.3))
                .frame(width: 12, height: 1)
        }
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Logic

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
