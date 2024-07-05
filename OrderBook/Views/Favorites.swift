import SwiftUI
import SwiftData

struct Favorites: View {
    // SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate { $0.isFavorite },
        sort: [SortDescriptor(\Book.favoriteRanking)]
    ) private var books: [Book]
    
    // View Model
    @State private var bookSearchVM = BookSearchViewModel()
    
    // View-Dependant
    @State private var largestRanking: UInt = 0
    @State private var isShowingCheckmark = false
    @State private var isAnimatingCheckmark = false
    
    private let bookInfoService = BookInfoService()

    var body: some View {
        List {
            if bookSearchVM.isSearching {
                ForEach(bookSearchVM.searchResults, id: \.isbn) { bookDetails in
                    searchResultButton(for: bookDetails)
                }
            } else {
                ForEach(books) { book in
                    if let details = book.details {
                        NavigationLink {
                            Text("Item at \(book.dateAdded, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            BookPreview(book: details)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            swipeActionButtons(for: book)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveBooks)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .navigationTitle("Favorites")
        .searchable(text: $bookSearchVM.searchString, prompt: "Search Books")
        .overlay {
            if isShowingCheckmark {
                checkmarkOverlay
            }
        }
        .onChange(of: isShowingCheckmark) {
            if !isShowingCheckmark {
                isAnimatingCheckmark = false
            }
        }
        .onAppear { updateRankings() }
    }
    
    private var checkmarkOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .foregroundStyle(.thickMaterial)
            
            VStack {
                Image(systemName: isAnimatingCheckmark ? "checkmark.diamond.fill" : "diamond.fill")
                    .resizable()
                    .scaledToFit()
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                    .task {
                        try? await Task.sleep(for: .milliseconds(100))
                        isAnimatingCheckmark.toggle()
                    }
                
                Text("Book Added")
                    .bold()
            }
            .foregroundStyle(.gray.mix(with: .black, by: 0.2))
            .padding(40)
        }
        .frame(width: 200, height: 200)
    }
    
    // MARK: - View Functions
    
    @ViewBuilder
    private func swipeActionButtons(for book: Book) -> some View {
        Button {
            withAnimation {
                book.isFavorite.toggle()
            }
        } label: {
            if book.isFavorite {
                Label("Unfavorite", systemImage: "heart.slash.fill")
            } else {
                Label("Favorite", systemImage: "heart.fill")
            }
        }
        .tint(.green)
    }
    
    private func searchResultButton(for bookDetails: BookDetails) -> some View {
        Button {
            let newItem = Book(isbn: bookDetails.isbn, details: bookDetails, ranking: largestRanking + 1)
            largestRanking += 1
            
            modelContext.insert(newItem)
            
            Task {
                withAnimation(.linear(duration: 0.1)) {
                    isShowingCheckmark = true
                }
                
                try? await Task.sleep(for: .milliseconds(1100))
                
                withAnimation(.linear(duration: 0.1)) {
                    isShowingCheckmark = false
                }
            }
        } label: {
            BookPreview(book: bookDetails)
        }
    }
    
    // MARK: - Functions
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(books[index])
            }
            
            updateRankings()
        }
    }
    
    private func updateRankings(_ books: [Book]? = nil) {
        for (index, book) in (books ?? self.books).enumerated() {
            book.favoriteRanking = UInt(index)
            
            if book.details == nil {
                Task {
                    do {
                        book.details = try await bookInfoService.getBookInfo(isbn: book.isbn)
                    } catch {
                        print(error)
                    }
                }
            }
            
            guard book.favoriteRanking > largestRanking else { continue }
            
            largestRanking = book.favoriteRanking
        }
    }
    
    private func moveBooks(from offsetsToMove: IndexSet, to newIndex: Int) {
        // Make a copy of the current list of items
        var updatedBooks = books

        // Apply the move operation to the items
        updatedBooks.move(fromOffsets: offsetsToMove, toOffset: newIndex)

        updateRankings(updatedBooks)
        
        do {
            try modelContext.save()
        } catch {
            print(error)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Favorites()
            .modelContainer(for: Book.self, inMemory: true)
    }
}
