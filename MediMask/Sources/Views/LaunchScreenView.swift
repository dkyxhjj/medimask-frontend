import SwiftUI

struct LaunchScreenView: View {
    @State private var progress: CGFloat = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.6
    @State private var ringRotation: Double = 0
    @State private var outerRingRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var orbOffset1: CGSize = .zero
    @State private var orbOffset2: CGSize = .zero
    @State private var orbOffset3: CGSize = .zero
    @State private var taglineOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var titleShimmer: CGFloat = -1
    @State private var lettersRevealed: Int = 0
    @State private var particlePhase: CGFloat = 0
    @State private var iconBounce: Bool = false
    @State private var ringPulse: Bool = false
    @State private var bgHue: Double = 0
    private let appName = Array("MediMask")

    let onFinished: () -> Void

    private let accentBlue = Color(red: 0.29, green: 0.42, blue: 0.97)
    private let accentPurple = Color(red: 0.48, green: 0.32, blue: 0.95)
    private let accentCyan = Color(red: 0.25, green: 0.65, blue: 0.96)

    var body: some View {
        ZStack {
            // Animated gradient background with hue shift
            LinearGradient(
                colors: [
                    Color(red: 0.06 + bgHue * 0.02, green: 0.07, blue: 0.16 + bgHue * 0.03),
                    Color(red: 0.10, green: 0.11 + bgHue * 0.01, blue: 0.22 + bgHue * 0.02),
                    Color(red: 0.08 + bgHue * 0.01, green: 0.09, blue: 0.19)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentBlue.opacity(0.3), accentBlue.opacity(0)],
                        center: .center, startRadius: 0, endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(orbOffset1)
                .blur(radius: 40)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentPurple.opacity(0.25), accentPurple.opacity(0)],
                        center: .center, startRadius: 0, endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(orbOffset2)
                .blur(radius: 35)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentCyan.opacity(0.2), accentCyan.opacity(0)],
                        center: .center, startRadius: 0, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(orbOffset3)
                .blur(radius: 30)

            // Floating particles
            GeometryReader { geo in
                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) * (.pi * 2 / 12)
                    let radius: CGFloat = 130 + CGFloat(i % 3) * 40
                    Circle()
                        .fill(
                            [accentCyan, accentBlue, accentPurple][i % 3]
                                .opacity(Double(0.15 + sin(Double(particlePhase) * .pi * 2 + angle) * 0.15))
                        )
                        .frame(width: CGFloat(2 + i % 3), height: CGFloat(2 + i % 3))
                        .position(
                            x: geo.size.width / 2 + cos(angle + Double(particlePhase) * .pi * 2) * radius,
                            y: geo.size.height * 0.35 + sin(angle + Double(particlePhase) * .pi * 2) * radius * 0.6
                        )
                        .blur(radius: CGFloat(i % 2))
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 32) {
                Spacer()

                // Logo with animated rings
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(accentBlue.opacity(glowOpacity * 0.2))
                        .frame(width: 180, height: 180)
                        .blur(radius: 35)
                        .scaleEffect(ringPulse ? 1.15 : 1.0)

                    // Outer dashed ring
                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1, dash: [4, 6])
                        )
                        .foregroundColor(accentCyan.opacity(0.3))
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(outerRingRotation))
                        .scaleEffect(ringPulse ? 1.05 : 1.0)

                    // Middle gradient ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    accentBlue.opacity(0.6),
                                    accentPurple.opacity(0.4),
                                    accentCyan.opacity(0.6),
                                    accentBlue.opacity(0.1),
                                    accentBlue.opacity(0.6)
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(ringRotation))

                    // Inner solid ring
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentBlue.opacity(0.15), accentPurple.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [accentBlue.opacity(0.5), accentPurple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    Image(systemName: "eye.slash")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentCyan, accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconBounce ? 1.1 : 1.0)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                // Animated app name — letter-by-letter with shimmer
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        ForEach(0..<appName.count, id: \.self) { i in
                            Text(String(appName[i]))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [accentCyan, .white, accentBlue],
                                        startPoint: UnitPoint(x: titleShimmer + CGFloat(i) * 0.05, y: 0),
                                        endPoint: UnitPoint(x: titleShimmer + CGFloat(i) * 0.05 + 0.3, y: 1)
                                    )
                                )
                                .opacity(i < lettersRevealed ? 1 : 0)
                                .offset(y: i < lettersRevealed ? 0 : 16)
                                .scaleEffect(i < lettersRevealed ? 1.0 : 0.5)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.6)
                                        .delay(Double(i) * 0.07),
                                    value: lettersRevealed
                                )
                        }
                    }

                    Text("PRIVACY SHIELD")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(4)
                        .foregroundColor(accentCyan.opacity(0.6))
                        .opacity(taglineOpacity)
                        .scaleEffect(x: taglineOpacity, y: 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0), value: taglineOpacity)
                }

                Spacer()

                // Progress section
                VStack(spacing: 16) {
                    // Custom progress bar with shimmer
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [accentBlue, accentPurple, accentCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.4), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 60)
                                        .offset(x: shimmerOffset)
                                        .mask(
                                            RoundedRectangle(cornerRadius: 4)
                                                .frame(width: geo.size.width * progress, height: 4)
                                        )
                                )

                            if progress > 0.05 {
                                Circle()
                                    .fill(accentCyan)
                                    .frame(width: 8, height: 8)
                                    .blur(radius: 4)
                                    .offset(x: geo.size.width * progress - 4)
                            }
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 48)

                    Text("protect patient privacy.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .opacity(taglineOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Orb animations
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                orbOffset1 = CGSize(width: 60, height: -80)
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(0.5)) {
                orbOffset2 = CGSize(width: -70, height: 60)
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1)) {
                orbOffset3 = CGSize(width: 40, height: 90)
            }

            // Floating particles orbit
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                particlePhase = 1
            }

            // Background hue shift
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                bgHue = 1
            }

            // Logo entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.2)) {
                logoOpacity = 1
                logoScale = 1
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
                glowOpacity = 1
            }

            // Ring pulse
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.3)) {
                ringPulse = true
            }

            // Icon bounce
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.8)) {
                iconBounce = true
            }

            // Ring rotations
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                outerRingRotation = -360
            }

            // Letter-by-letter reveal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                lettersRevealed = appName.count
            }

            // Title shimmer sweep
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(1.0)) {
                titleShimmer = 2
            }

            // Tagline fade in
            withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
                taglineOpacity = 1
            }

            // Progress bar
            withAnimation(.easeInOut(duration: 1.8).delay(0.4)) {
                progress = 1
            }

            // Shimmer
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false).delay(0.6)) {
                shimmerOffset = 300
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                onFinished()
            }
        }
    }
}

#Preview {
    LaunchScreenView(onFinished: {})
}
