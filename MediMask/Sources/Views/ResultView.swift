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
    @State private var processingTime: (faceDetection: Int, ocr: Int, total: Int) = (161, 406, 2232)

    private let accentBlue = Color(red: 0.29, green: 0.42, blue: 0.97)
    private let accentPurple = Color(red: 0.48, green: 0.32, blue: 0.95)
    private let accentCyan = Color(red: 0.25, green: 0.65, blue: 0.96)
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.55)
    private let accentRed = Color(red: 0.92, green: 0.32, blue: 0.34)
    private let bgDark = Color(red: 0.06, green: 0.07, blue: 0.16)
    private let bgMid = Color(red: 0.10, green: 0.11, blue: 0.22)
    private let cardBg = Color(red: 0.11, green: 0.12, blue: 0.23)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [bgDark, bgMid, bgDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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

            // Fullscreen image overlay
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
        }
    }

    // MARK: - Image Header

    private var imageHeader: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Full-width image — tap to go fullscreen
                Image(uiImage: showingOriginal ? originalImage : (displayImage ?? blurredImage))
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .clear, bgDark.opacity(0.6), bgDark],
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
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 56)
                .padding(.leading, 20)

                // Result label + subtitle
                VStack(spacing: 4) {
                    Spacer()
                    Text("Result")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Safe-to-share copy created")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // Original / Scrubbed toggle
            HStack(spacing: 0) {
                imageToggleButton(title: "Original", isSelected: showingOriginal) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showingOriginal = true
                    }
                }
                imageToggleButton(title: "Scrubbed", isSelected: !showingOriginal) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showingOriginal = false
                    }
                }
            }
            .padding(4)
            .background(
                Capsule().fill(Color.white.opacity(0.06))
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .opacity(appearAnimation ? 1 : 0)
    }

    private func imageToggleButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(
                                LinearGradient(
                                    colors: [accentBlue, accentPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                )
        }
    }

    // MARK: - Fullscreen Image Overlay

    private var fullscreenImageOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: showingOriginal ? originalImage : (displayImage ?? blurredImage))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: showingOriginal)

            // Top bar
            VStack {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            imageFullscreen = false
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    // Toggle in fullscreen
                    HStack(spacing: 0) {
                        imageToggleButton(title: "Original", isSelected: showingOriginal) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingOriginal = true
                            }
                        }
                        imageToggleButton(title: "Scrubbed", isSelected: !showingOriginal) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingOriginal = false
                            }
                        }
                    }
                    .padding(3)
                    .background(Capsule().fill(Color.white.opacity(0.1)))

                    Spacer()

                    // Spacer to balance the X button
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

    // MARK: - Redaction Controls

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Redaction Controls")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Presets row
            HStack(spacing: 10) {
                ForEach(PrivacyPreset.allCases, id: \.self) { preset in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedPreset = preset
                            applyPreset(preset)
                        }
                    } label: {
                        Text(preset.rawValue.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(selectedPreset == preset ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Group {
                                    if selectedPreset == preset {
                                        Capsule().fill(
                                            LinearGradient(
                                                colors: [accentBlue, accentPurple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    } else {
                                        Capsule()
                                            .fill(Color.white.opacity(0.06))
                                            .overlay(
                                                Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            )
                    }
                }
            }

            // Quick actions
            HStack(spacing: 10) {
                quickActionButton(title: "BLUR ALL", icon: "eye.slash") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        for i in regions.indices { regions[i].isBlurred = true }
                        reprocessImage()
                    }
                }
                quickActionButton(title: "KEEP ALL", icon: "eye") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        for i in regions.indices { regions[i].isBlurred = false }
                        reprocessImage()
                    }
                }
            }

            // Blur intensity slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Blur Intensity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(blurRadius))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(accentCyan)
                }

                Slider(value: Binding(
                    get: { blurRadius },
                    set: { newValue in
                        blurRadius = newValue
                        reprocessImage()
                    }
                ), in: 5...50, step: 1)
                .tint(accentBlue)
            }
            .padding(.top, 4)

            // Individual regions
            VStack(spacing: 2) {
                ForEach($regions) { $region in
                    regionRow(region: $region)
                }
            }
        }
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(accentCyan.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(accentCyan.opacity(0.08))
                    .overlay(
                        Capsule().strokeBorder(accentCyan.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    private func regionRow(region: Binding<DetectedRegion>) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentBlue.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: region.wrappedValue.icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(region.wrappedValue.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text(region.wrappedValue.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            region.wrappedValue.isBlurred
                                ? accentRed
                                : Color.white.opacity(0.15)
                        )
                    )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBg.opacity(0.5))
        )
    }

    // MARK: - Share Section

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
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Share Scrubbed\nImage")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.leading)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [accentBlue, accentPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: accentBlue.opacity(0.25), radius: 12, y: 4)
            }

            Button {
                guard let img = displayImage else { return }
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    saveConfirmation = true
                }
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
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Detection Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Detection Summary")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            let blurredCount = regions.filter(\.isBlurred).count
            let totalCount = regions.count

            VStack(alignment: .leading, spacing: 8) {
                ForEach(regionSummary(), id: \.label) { item in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(accentBlue.opacity(0.4))
                            .frame(width: 6, height: 6)
                        Text("\(item.label): \(item.count)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                HStack(spacing: 10) {
                    Circle()
                        .fill(accentCyan.opacity(0.5))
                        .frame(width: 6, height: 6)
                    Text("Total regions: \(totalCount)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }

                HStack(spacing: 10) {
                    Circle()
                        .fill(accentRed.opacity(0.5))
                        .frame(width: 6, height: 6)
                    Text("Blurred: \(blurredCount) / \(totalCount)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Leak Warning

    private var leakSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What This Data Could Leak")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            let unblurred = regions.filter { !$0.isBlurred }
            if unblurred.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(accentGreen)
                    Text("No high-risk identifiers were detected in this scan.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(unblurred) { region in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(accentRed.opacity(0.8))
                            Text("\(region.label) is visible and may leak identity.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
    }

    // MARK: - Processing Time

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Processing Time")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 6) {
                timingRow(label: "Face detection", value: "\(processingTime.faceDetection) ms")
                timingRow(label: "OCR", value: "\(processingTime.ocr) ms")
                timingRow(label: "PHI redact", value: "\(processingTime.total) ms")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .opacity(appearAnimation ? 1 : 0)
    }

    private func timingRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(accentCyan.opacity(0.8))
        }
    }

    // MARK: - Logic

    private func generateDetections() -> [DetectedRegion] {
        [
            DetectedRegion(
                label: "PERSON NAME",
                description: "Person Name – Melange Text Anonymizer",
                icon: "person.fill",
                isBlurred: true
            ),
            DetectedRegion(
                label: "SENSITIVE TEXT",
                description: "Sensitive Text – Melange Text Anonymizer",
                icon: "doc.text.fill",
                isBlurred: true
            ),
            DetectedRegion(
                label: "DATE",
                description: "Date – Temporal Pattern Matcher",
                icon: "calendar",
                isBlurred: true
            ),
            DetectedRegion(
                label: "LOCATION",
                description: "Location – Geospatial Pattern Detector",
                icon: "mappin.circle",
                isBlurred: false
            ),
        ]
    }

    private func applyPreset(_ preset: PrivacyPreset) {
        switch preset {
        case .balanced:
            for i in regions.indices {
                regions[i].isBlurred = regions[i].label == "PERSON NAME"
                    || regions[i].label == "SENSITIVE TEXT"
                    || regions[i].label == "DATE OF BIRTH"
            }
        case .highPrivacy:
            for i in regions.indices {
                regions[i].isBlurred = true
            }
        }
        reprocessImage()
    }

    private func reprocessImage() {
        let anyBlurred = regions.contains(where: \.isBlurred)
        Task.detached(priority: .userInitiated) {
            let result: UIImage?
            if anyBlurred {
                result = await applyBlur(to: originalImage, radius: blurRadius)
            } else {
                result = originalImage
            }
            await MainActor.run {
                if let result {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        displayImage = result
                    }
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
        var summary: [(label: String, count: Int)] = []
        let grouped = Dictionary(grouping: regions, by: \.label)
        for (label, items) in grouped.sorted(by: { $0.key < $1.key }) {
            summary.append((label: label, count: items.count))
        }
        return summary
    }
}

#Preview {
    ResultView(
        originalImage: UIImage(systemName: "photo")!,
        blurredImage: UIImage(systemName: "photo")!,
        onDismiss: {}
    )
}
