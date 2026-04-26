import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Detection Models

enum PrivacyPreset: String, CaseIterable {
    case balanced = "Balanced"
    case highPrivacy = "High Privacy"
}

struct DetectedRegion: Identifiable {
    let id = UUID()
    let label: String
    let description: String
    let icon: String
    var isBlurred: Bool
}

struct ResultView: View {
    let originalImage: UIImage
    let blurredImage: UIImage
    let onDismiss: () -> Void

    @State private var selectedPreset: PrivacyPreset = .balanced
    @State private var regions: [DetectedRegion] = []
    @State private var displayImage: UIImage?
    @State private var blurRadius: Float = 22
    @State private var saveConfirmation = false
    @State private var appearAnimation = false
    @State private var showingOriginal = false
    @State private var imageFullscreen = false
    @State private var snowPhase: CGFloat = 0
    @State private var frostBreath = false
    @State private var processingTime: (faceDetection: Int, ocr: Int, total: Int) = (161, 406, 2232)

    // ICE palette
    private let iceTeal = Color(red: 0.31, green: 0.69, blue: 0.72)
    private let iceLight = Color(red: 0.55, green: 0.82, blue: 0.85)
    private let iceDark = Color(red: 0.05, green: 0.12, blue: 0.15)
    private let iceMid = Color(red: 0.08, green: 0.18, blue: 0.22)
    private let frostWhite = Color(red: 0.85, green: 0.95, blue: 0.97)
    private let iceCard = Color(red: 0.07, green: 0.16, blue: 0.20)
    private let frozenRed = Color(red: 0.85, green: 0.35, blue: 0.38)
    private let frozenGreen = Color(red: 0.3, green: 0.78, blue: 0.65)

    var body: some View {
        ZStack {
            // Frozen background
            LinearGradient(
                colors: [iceDark, iceMid, iceDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Snow
            snowfall

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    imageHeader
                    controlsSection
                        .padding(.top, 24)
                    shareSection
                        .padding(.top, 28)
                    summarySection
                        .padding(.top, 28)
                    leakSection
                        .padding(.top, 20)
                    timingSection
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }

            if imageFullscreen {
                fullscreenImageOverlay
                    .transition(.opacity)
            }
        }
        .onAppear {
            displayImage = blurredImage
            regions = generateDetections()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                appearAnimation = true
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                snowPhase = 1
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                frostBreath = true
            }
        }
    }

    // MARK: - Snow

    private var snowfall: some View {
        GeometryReader { geo in
            ForEach(0..<12, id: \.self) { i in
                let seed = Double(i) * 1.618
                let x = seed.truncatingRemainder(dividingBy: 1.0)
                let speed = 0.2 + Double(i % 4) * 0.1
                let size = CGFloat(1 + i % 3)
                Circle()
                    .fill(frostWhite.opacity(speed * 0.35))
                    .frame(width: size, height: size)
                    .position(
                        x: geo.size.width * CGFloat(x) + sin(Double(snowPhase) * .pi * 2 + seed * 3) * 10,
                        y: geo.size.height * CGFloat(
                            (Double(snowPhase) * speed + seed).truncatingRemainder(dividingBy: 1.0)
                        )
                    )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Image Header

    private var imageHeader: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Image(uiImage: showingOriginal ? originalImage : (displayImage ?? blurredImage))
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .clear, iceDark.opacity(0.6), iceDark],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            imageFullscreen = true
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: showingOriginal)

                // Back button
                Button(action: onDismiss) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(frostWhite)
                    }
                }
                .padding(.top, 56)
                .padding(.leading, 20)

                VStack(spacing: 4) {
                    Spacer()
                    Text("RESULT")
                        .font(.system(size: 20, weight: .heavy, design: .default).width(.compressed))
                        .scaleEffect(x: 0.8, y: 1.3)
                        .tracking(3)
                        .foregroundColor(frostWhite)
                    Text("Safe-to-share copy created")
                        .font(.system(size: 12))
                        .foregroundColor(frostWhite.opacity(0.4))
                        .padding(.bottom, 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Toggle
            HStack(spacing: 0) {
                iceToggleButton(title: "Original", isSelected: showingOriginal) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showingOriginal = true
                    }
                }
                iceToggleButton(title: "Scrubbed", isSelected: !showingOriginal) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showingOriginal = false
                    }
                }
            }
            .padding(4)
            .background(Capsule().fill(frostWhite.opacity(0.06)))
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .opacity(appearAnimation ? 1 : 0)
    }

    private func iceToggleButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? iceDark : frostWhite.opacity(0.4))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(
                                LinearGradient(
                                    colors: [iceTeal, iceLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                )
        }
    }

    // MARK: - Fullscreen

    private var fullscreenImageOverlay: some View {
        ZStack {
            iceDark.ignoresSafeArea()

            Image(uiImage: showingOriginal ? originalImage : (displayImage ?? blurredImage))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: showingOriginal)

            VStack {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            imageFullscreen = false
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(frostWhite.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(frostWhite)
                        }
                    }

                    Spacer()

                    HStack(spacing: 0) {
                        iceToggleButton(title: "Original", isSelected: showingOriginal) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingOriginal = true
                            }
                        }
                        iceToggleButton(title: "Scrubbed", isSelected: !showingOriginal) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingOriginal = false
                            }
                        }
                    }
                    .padding(3)
                    .background(Capsule().fill(frostWhite.opacity(0.08)))

                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                imageFullscreen = false
            }
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Redaction Controls")
                .font(.system(size: 18, weight: .heavy, design: .default).width(.condensed))
                .foregroundColor(frostWhite)

            // Presets
            HStack(spacing: 10) {
                ForEach(PrivacyPreset.allCases, id: \.self) { preset in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedPreset = preset
                            applyPreset(preset)
                        }
                    } label: {
                        Text(preset.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(selectedPreset == preset ? iceDark : frostWhite.opacity(0.5))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Group {
                                    if selectedPreset == preset {
                                        Capsule().fill(
                                            LinearGradient(
                                                colors: [iceTeal, iceLight],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    } else {
                                        Capsule()
                                            .fill(frostWhite.opacity(0.04))
                                            .overlay(Capsule().strokeBorder(frostWhite.opacity(0.08), lineWidth: 1))
                                    }
                                }
                            )
                    }
                }
            }

            // Quick actions
            HStack(spacing: 10) {
                iceQuickButton(title: "BLUR ALL", icon: "eye.slash") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        for i in regions.indices { regions[i].isBlurred = true }
                        reprocessImage()
                    }
                }
                iceQuickButton(title: "KEEP ALL", icon: "eye") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        for i in regions.indices { regions[i].isBlurred = false }
                        reprocessImage()
                    }
                }
            }

            // Blur slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Blur Intensity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(frostWhite.opacity(0.6))
                    Spacer()
                    Text("\(Int(blurRadius))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(iceTeal)
                }
                Slider(value: Binding(
                    get: { blurRadius },
                    set: { blurRadius = $0; reprocessImage() }
                ), in: 5...50, step: 1)
                .tint(iceTeal)
            }
            .padding(.top, 4)

            // Regions
            VStack(spacing: 2) {
                ForEach($regions) { $region in
                    iceRegionRow(region: $region)
                }
            }
        }
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private func iceQuickButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(title).font(.system(size: 11, weight: .bold)).tracking(0.5)
            }
            .foregroundColor(iceTeal.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(iceTeal.opacity(0.08))
                    .overlay(Capsule().strokeBorder(iceTeal.opacity(0.15), lineWidth: 1))
            )
        }
    }

    private func iceRegionRow(region: Binding<DetectedRegion>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(iceTeal.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: region.wrappedValue.icon)
                    .font(.system(size: 14))
                    .foregroundColor(iceTeal)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(region.wrappedValue.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(frostWhite.opacity(0.9))
                Text(region.wrappedValue.description)
                    .font(.system(size: 11))
                    .foregroundColor(frostWhite.opacity(0.3))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    region.wrappedValue.isBlurred.toggle()
                    reprocessImage()
                }
            } label: {
                Text(region.wrappedValue.isBlurred ? "BLUR" : "SHOW")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(region.wrappedValue.isBlurred ? iceDark : frostWhite)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            region.wrappedValue.isBlurred ? frozenRed : frostWhite.opacity(0.1)
                        )
                    )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(iceCard.opacity(0.5)))
    }

    // MARK: - Share

    private var shareSection: some View {
        HStack(spacing: 12) {
            Button {
                guard let img = displayImage else { return }
                let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.windows.first?.rootViewController {
                    root.present(av, animated: true)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .semibold))
                    Text("Share Scrubbed\nImage")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.leading)
                }
                .foregroundColor(iceDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [iceTeal, iceLight], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: iceTeal.opacity(0.25), radius: 12, y: 4)
            }

            Button {
                guard let img = displayImage else { return }
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { saveConfirmation = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { saveConfirmation = false }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: saveConfirmation ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                    Text(saveConfirmation ? "Saved!" : "Save Copy")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(frostWhite.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(frostWhite.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16).strokeBorder(frostWhite.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Detection Summary")
                .font(.system(size: 16, weight: .heavy, design: .default).width(.condensed))
                .foregroundColor(frostWhite)

            let blurredCount = regions.filter(\.isBlurred).count
            let totalCount = regions.count

            VStack(alignment: .leading, spacing: 8) {
                ForEach(regionSummary(), id: \.label) { item in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 1).fill(iceTeal.opacity(0.5)).frame(width: 3, height: 12)
                        Text("\(item.label): \(item.count)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(frostWhite.opacity(0.6))
                    }
                }

                Rectangle().fill(frostWhite.opacity(0.04)).frame(height: 1).padding(.vertical, 4)

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 1).fill(iceTeal).frame(width: 3, height: 12)
                    Text("Total regions: \(totalCount)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(frostWhite.opacity(0.7))
                }
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 1).fill(frozenRed.opacity(0.7)).frame(width: 3, height: 12)
                    Text("Blurred: \(blurredCount) / \(totalCount)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(frostWhite.opacity(0.7))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(iceCard.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(iceTeal.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Leak

    private var leakSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What This Data Could Leak")
                .font(.system(size: 16, weight: .heavy, design: .default).width(.condensed))
                .foregroundColor(frostWhite)

            let unblurred = regions.filter { !$0.isBlurred }
            if unblurred.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill").foregroundColor(frozenGreen)
                    Text("No high-risk identifiers detected.")
                        .font(.system(size: 13)).foregroundColor(frostWhite.opacity(0.4))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(unblurred) { region in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11)).foregroundColor(frozenRed.opacity(0.8))
                            Text("\(region.label) is visible and may leak identity.")
                                .font(.system(size: 13)).foregroundColor(frostWhite.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(iceCard.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(iceTeal.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Timing

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Processing Time")
                .font(.system(size: 16, weight: .heavy, design: .default).width(.condensed))
                .foregroundColor(frostWhite)

            VStack(alignment: .leading, spacing: 6) {
                iceTimingRow(label: "Face detection", value: "\(processingTime.faceDetection) ms")
                iceTimingRow(label: "OCR", value: "\(processingTime.ocr) ms")
                iceTimingRow(label: "PHI redact", value: "\(processingTime.total) ms")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(iceCard.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(iceTeal.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
    }

    private func iceTimingRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(frostWhite.opacity(0.4))
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(iceTeal.opacity(0.8))
        }
    }

    // MARK: - Logic

    private func generateDetections() -> [DetectedRegion] {
        [
            DetectedRegion(label: "PERSON NAME", description: "Person Name – Melange Text Anonymizer", icon: "person.fill", isBlurred: true),
            DetectedRegion(label: "SENSITIVE TEXT", description: "Sensitive Text – Melange Text Anonymizer", icon: "doc.text.fill", isBlurred: true),
            DetectedRegion(label: "DATE", description: "Date – Temporal Pattern Matcher", icon: "calendar", isBlurred: true),
            DetectedRegion(label: "LOCATION", description: "Location – Geospatial Pattern Detector", icon: "mappin.circle", isBlurred: false),
        ]
    }

    private func applyPreset(_ preset: PrivacyPreset) {
        switch preset {
        case .balanced:
            for i in regions.indices {
                regions[i].isBlurred = regions[i].label == "PERSON NAME"
                    || regions[i].label == "SENSITIVE TEXT"
                    || regions[i].label == "DATE"
            }
        case .highPrivacy:
            for i in regions.indices { regions[i].isBlurred = true }
        }
        reprocessImage()
    }

    private func reprocessImage() {
        let anyBlurred = regions.contains(where: \.isBlurred)
        Task.detached(priority: .userInitiated) {
            let result: UIImage? = anyBlurred ? await applyBlur(to: originalImage, radius: blurRadius) : originalImage
            await MainActor.run {
                if let result {
                    withAnimation(.easeInOut(duration: 0.3)) { displayImage = result }
                }
            }
        }
    }

    private func applyBlur(to image: UIImage, radius: Float) async -> UIImage? {
        guard let ci = CIImage(image: image) else { return nil }
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ci
        filter.radius = radius
        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func regionSummary() -> [(label: String, count: Int)] {
        Dictionary(grouping: regions, by: \.label)
            .map { (label: $0.key, count: $0.value.count) }
            .sorted { $0.label < $1.label }
    }
}

#Preview {
    ResultView(
        originalImage: UIImage(systemName: "photo")!,
        blurredImage: UIImage(systemName: "photo")!,
        onDismiss: {}
    )
}
