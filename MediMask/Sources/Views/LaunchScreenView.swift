import SwiftUI

struct LaunchScreenView: View {
    @State private var progress: CGFloat = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.65), lineWidth: 1.5)
                            .frame(width: 88, height: 88)
                        Image(systemName: "eye.slash")
                            .font(.system(size: 34, weight: .light))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    Text("MediMask")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .opacity(logoOpacity)
                .scaleEffect(logoScale)

                Spacer()

                // Progress bar
                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.85))
                                .frame(width: geo.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 48)

                    Text("protect patient privacy.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 1
                logoScale = 1
            }
            withAnimation(.easeInOut(duration: 1.6).delay(0.3)) {
                progress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onFinished()
            }
        }
    }
}

#Preview {
    LaunchScreenView(onFinished: {})
}
