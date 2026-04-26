import SwiftUI

struct LaunchScreenView: View {
    @State private var progress: CGFloat = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.6
    @State private var ringRotation: Double = 0
    @State private var outerRingRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var titleShimmer: CGFloat = -1
    @State private var lettersRevealed: Int = 0
    @State private var snowPhase: CGFloat = 0
    @State private var iconBounce: Bool = false
    @State private var ringPulse: Bool = false
    @State private var frostBreath: Bool = false
    private let appName = Array("MEDIMASK")

    let onFinished: () -> Void

    // ICE palette
    private let iceTeal = Color(red: 0.31, green: 0.69, blue: 0.72)
    private let iceLight = Color(red: 0.55, green: 0.82, blue: 0.85)
    private let iceDark = Color(red: 0.05, green: 0.12, blue: 0.15)
    private let iceMid = Color(red: 0.08, green: 0.18, blue: 0.22)
    private let frostWhite = Color(red: 0.85, green: 0.95, blue: 0.97)

    var body: some View {
        ZStack {
            // Frozen gradient background
            LinearGradient(
                colors: [iceDark, iceMid, iceDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Falling snow / ice particles
            GeometryReader { geo in
                ForEach(0..<20, id: \.self) { i in
                    let seed = Double(i) * 1.618
                    let x = (seed.truncatingRemainder(dividingBy: 1.0))
                    let speed = 0.3 + (Double(i % 5)) * 0.15
                    let size = CGFloat(1 + i % 4)
                    Circle()
                        .fill(frostWhite.opacity(speed * 0.5))
                        .frame(width: size, height: size)
                        .position(
                            x: geo.size.width * CGFloat(x) + sin(Double(snowPhase) * .pi * 2 + seed * 3) * 15,
                            y: geo.size.height * CGFloat(
                                (Double(snowPhase) * speed + seed)
                                    .truncatingRemainder(dividingBy: 1.0)
                            )
                        )
                        .blur(radius: size > 3 ? 1 : 0)
                }
            }
            .allowsHitTesting(false)

            // Frozen mist orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [iceTeal.opacity(0.2), .clear],
                        center: .center, startRadius: 0, endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -40, y: -100)
                .blur(radius: 50)
                .opacity(frostBreath ? 0.8 : 0.4)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [iceLight.opacity(0.12), .clear],
                        center: .center, startRadius: 0, endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: 60, y: 150)
                .blur(radius: 45)
                .opacity(frostBreath ? 0.6 : 0.3)

            VStack(spacing: 32) {
                Spacer()

                // Logo with icy rings
                ZStack {
                    // Frost glow
                    Circle()
                        .fill(iceTeal.opacity(glowOpacity * 0.2))
                        .frame(width: 180, height: 180)
                        .blur(radius: 40)
                        .scaleEffect(ringPulse ? 1.15 : 1.0)

                    // Outer ice crystal ring
                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1, dash: [3, 5])
                        )
                        .foregroundColor(iceLight.opacity(0.3))
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(outerRingRotation))
                        .scaleEffect(ringPulse ? 1.05 : 1.0)

                    // Inner frost ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    iceTeal.opacity(0.6),
                                    iceLight.opacity(0.3),
                                    frostWhite.opacity(0.5),
                                    iceTeal.opacity(0.1),
                                    iceTeal.opacity(0.6)
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(ringRotation))

                    // Core ice circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iceTeal.opacity(0.15), iceMid.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .strokeBorder(frostWhite.opacity(0.2), lineWidth: 1.5)
                        )

                    Image(systemName: "eye.slash")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [frostWhite, iceTeal],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(iconBounce ? 1.1 : 1.0)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                // ICEMAN style title
                VStack(spacing: 10) {
                    HStack(spacing: 1) {
                        ForEach(0..<appName.count, id: \.self) { i in
                            Text(String(appName[i]))
                                .font(.system(size: 34, weight: .heavy, design: .default).width(.compressed))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [frostWhite, iceTeal, iceLight],
                                        startPoint: UnitPoint(x: titleShimmer + CGFloat(i) * 0.05, y: 0),
                                        endPoint: UnitPoint(x: titleShimmer + CGFloat(i) * 0.05 + 0.3, y: 1)
                                    )
                                )
                                .scaleEffect(x: 0.75, y: 1.4)
                                .opacity(i < lettersRevealed ? 1 : 0)
                                .offset(y: i < lettersRevealed ? 0 : 20)
                                .scaleEffect(i < lettersRevealed ? 1.0 : 0.5)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.6)
                                        .delay(Double(i) * 0.07),
                                    value: lettersRevealed
                                )
                        }
                    }

                    Text("S U B · Z E R O")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(iceTeal.opacity(0.6))
                        .opacity(taglineOpacity)
                        .scaleEffect(x: taglineOpacity, y: 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0), value: taglineOpacity)
                }

                Spacer()

                // Frost progress bar
                VStack(spacing: 16) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(frostWhite.opacity(0.06))
                                .frame(height: 3)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [iceTeal, iceLight, frostWhite],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.5), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 50)
                                        .offset(x: shimmerOffset)
                                        .mask(
                                            RoundedRectangle(cornerRadius: 4)
                                                .frame(width: geo.size.width * progress, height: 3)
                                        )
                                )

                            if progress > 0.05 {
                                Circle()
                                    .fill(frostWhite)
                                    .frame(width: 6, height: 6)
                                    .blur(radius: 3)
                                    .offset(x: geo.size.width * progress - 3)
                            }
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 48)

                    Text("freeze the noise.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(frostWhite.opacity(0.25))
                        .opacity(taglineOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Snow fall
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                snowPhase = 1
            }
            // Frost breath
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                frostBreath = true
            }
            // Logo entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.2)) {
                logoOpacity = 1
                logoScale = 1
            }
            // Glow
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowOpacity = 1
            }
            // Ring pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.3)) {
                ringPulse = true
            }
            // Icon
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.8)) {
                iconBounce = true
            }
            // Rings
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.linear(duration: 35).repeatForever(autoreverses: false)) {
                outerRingRotation = -360
            }
            // Letters
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                lettersRevealed = appName.count
            }
            // Title shimmer
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false).delay(1.0)) {
                titleShimmer = 2
            }
            // Tagline
            withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
                taglineOpacity = 1
            }
            // Progress
            withAnimation(.easeInOut(duration: 1.8).delay(0.4)) {
                progress = 1
            }
            // Shimmer
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false).delay(0.6)) {
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
