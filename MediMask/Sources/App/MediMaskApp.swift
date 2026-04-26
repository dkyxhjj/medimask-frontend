import SwiftUI

@main
struct MediMaskApp: App {
    @State private var isLaunching = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLaunching {
                    LaunchScreenView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isLaunching = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
        }
    }
}
