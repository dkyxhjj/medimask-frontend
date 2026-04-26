import SwiftUI

@main
struct MediMaskApp: App {
    @State private var isLaunching = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLaunching {
                    LaunchScreenView {
                        withAnimation(.easeInOut(duration: 0.7)) {
                            isLaunching = false
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                } else {
                    ContentView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97)),
                            removal: .opacity
                        ))
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
