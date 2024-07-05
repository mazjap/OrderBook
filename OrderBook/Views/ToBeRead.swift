import SwiftUI
import SwiftData

struct ToBeRead: View {
    /// SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    
    // View Model
    @State private var bookSearchVM = BookSearchViewModel()
    
    // View-Dependant
    @State private var largestRanking: UInt = 0
    @State private var isShowingCheckmark = false
    @State private var isAnimatingCheckmark = false
    
    private let bookInfoService = BookInfoService()
    
    init() {
        let readStatus = ReadingStatus.alreadyRead.rawValue
        
        let filter = #Predicate<Book> { $0.statusValue != readStatus }
        let sortDescriptor = SortDescriptor(\Book.ranking)
        
        self._books = Query(filter: filter, sort: [sortDescriptor])
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
                            BookPreview(book: details, isFavorite: book.isFavorite, rank: book.ranking &+ 1)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            swipeActionButtons(for: book)
                        }
                    }
                }
                .onMove(perform: moveBooks)
                .onDelete(perform: deleteItems)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button(action: addItem) {
                    Label {
                        Text("Add Item")
                    } icon: {
                        Image("houseStark")
                    }
                }
            }
        }
        .navigationTitle("To Be Read")
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
        let hasRead = book.status == .alreadyRead
        
        Button {
            withAnimation {
                if hasRead {
                    book.status = ReadingStatus.toRead
                    book.dateRead = nil
                } else {
                    book.status = ReadingStatus.alreadyRead
                    book.dateRead = Date()
                    updateRankings()
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
            print(bookDetails.isbn)
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
    
    private func addItem() {
        withAnimation {
            //           Game of Thones   Clash of Kings
            let isbns = ["9780553897845", "9780553897852",
            //           Storm of Swords  Feast for Crows
                         "9780553897876", "9780553900323",
            //           Dance with Dragons
                         "9780553385953"]
            
            Task.detached {
                do {
                    var tempDetailsList = [BookDetails]()
                    for isbn in isbns {
                        try await tempDetailsList.append(bookInfoService.getBookInfo(isbn: isbn))
                    }
                    
                    let detailsList = tempDetailsList
                    
                    await MainActor.run {
                        for details in detailsList {
                            modelContext.insert(Book(
                                isbn: details.isbn,
                                details: details,
                                ranking: largestRanking + 1,
                                favoriteRanking: .max,
                                status: .toRead,
                                isFavorite: false
                            ))
                            largestRanking += 1
                        }
                        
                        updateRankings()
                    }
                } catch {
                    print(error)
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(books[index])
            }
            
            updateRankings()
        }
    }
    
    private func updateRankings(_ books: [Book]? = nil) {
        largestRanking = 0
        _books.update()
        
        for (index, book) in (books ?? self.books).enumerated() {
            book.ranking = UInt(index)
            
            if book.details == nil {
                Task {
                    do {
                        book.details = try await bookInfoService.getBookInfo(isbn: book.isbn)
                    } catch {
                        print(error)
                    }
                }
            }
            
            guard book.ranking > largestRanking else { continue }
            
            largestRanking = book.ranking
        }
        
        try? modelContext.save()
        _books.update()
    }
    
    private func moveBooks(from offsetsToMove: IndexSet, to newIndex: Int) {
        // Make a copy of the current list of items
        var updatedBooks = books

        // Apply the move operation to the items
        updatedBooks.move(fromOffsets: offsetsToMove, toOffset: newIndex)

        updateRankings(updatedBooks)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ToBeRead()
            .modelContainer(for: Book.self, inMemory: true)
    }
}
