import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var items: [MediMaskModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        // TODO: fetch data
        isLoading = false
    }
}
