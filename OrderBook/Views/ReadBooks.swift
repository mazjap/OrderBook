import SwiftUI
import SwiftData

struct ReadBooks: View {
    // SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    
    // View Model
    @State private var bookSearchVM = BookSearchViewModel()
    
    // View-Dependant
    @State private var isShowingCheckmark = false
    @State private var isAnimatingCheckmark = false
    
    private let bookInfoService = BookInfoService()
    
    init() {
        let readStatus = ReadingStatus.alreadyRead.rawValue
        
        let filter = #Predicate<Book> { $0.statusValue == readStatus }
        let sort = SortDescriptor(\Book.dateRead)
        
        self._books = Query(filter: filter, sort: [sort])
    }

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
                            BookPreview(book: details, isFavorite: book.isFavorite)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            swipeActionButtons(for: book)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .navigationTitle("Previously Read")
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
        let hasRead = book.status == .alreadyRead
        
        Button {
            withAnimation {
                if hasRead {
                    book.status = ReadingStatus.toRead
                    book.dateRead = nil
                } else {
                    book.status = ReadingStatus.alreadyRead
                }
            }
        } label: {
            if hasRead {
                Label("Mark Unread", systemImage: "book.closed.fill")
            } else {
                Label("Mark Read", systemImage: "book.fill")
            }
        }
        .tint(.blue)
        
        Button {
            withAnimation {
                book.isFavorite.toggle()
                
                book.favoriteRanking = .max
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
            let newItem = Book(isbn: bookDetails.isbn, details: bookDetails, ranking: .max, dateRead: Date())
            
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
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReadBooks()
            .modelContainer(for: Book.self, inMemory: true)
    }
}
