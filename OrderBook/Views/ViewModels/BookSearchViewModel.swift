import SwiftUI

@MainActor
@Observable
final class BookSearchViewModel {
    var searchString = "" {
        didSet {
            searchTask?.cancel()
            searchTask = nil
            
            guard !searchString.isEmpty else {
                searchResults = []
                return
            }
            
            guard searchString.count > 2 else {
                return
            }
            
            queueSearch()
        }
    }
    var searchResults: [BookDetails] = []
    
    var isSearching: Bool {
        return !searchString.isEmpty && !searchResults.isEmpty
    }
    
    private var searchTask: Task<Void, Never>?
    
    func queueSearch() {
        guard !searchString.isEmpty else { return }
        let searchString = searchString
        
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            
            let service = BookInfoService()
            
            do {
                let results = try await service.getBookInfos(for: searchString)
                
                await MainActor.run {
                    self.searchResults = results
                }
            } catch {
                print(error)
            }
        }
    }
}
