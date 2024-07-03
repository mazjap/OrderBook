import SwiftUI
import SwiftData

struct ContentView: View {
    /// SwiftData
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Book.ranking)]) private var books: [Book]
    
    // View Model
    @State private var bookSearchVM = BookSearchViewModel()
    
    // View-Dependant
    @State private var largestRanking: UInt = 0
    @State private var isShowingCheckmark = false
    @State private var isAnimatingCheckmark = false
    
    private let bookInfoService = BookInfoService()

    var body: some View {
        NavigationSplitView {
            List {
                if bookSearchVM.isSearching {
                    ForEach(bookSearchVM.searchResults, id: \.isbn) { bookDetails in
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
                } else {
                    ForEach(books) { book in
                        if let details = book.details {
                            NavigationLink {
                                Text("Item at \(book.dateAdded, format: Date.FormatStyle(date: .numeric, time: .standard))")
                            } label: {
                                BookPreview(book: details)
                            }
                        }
                    }
                    .onMove { fromOffsets, toOffset in
                        print("Moving...")
                        // Make a copy of the current list of items
                        var updatedBooks = books

                        // Apply the move operation to the items
                        updatedBooks.move(fromOffsets: fromOffsets, toOffset: toOffset)

                        updateRankings(updatedBooks)
                        
                        do {
                            try modelContext.save()
                        } catch {
                            print(error)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("TBR")
        } detail: {
            Text("Select an item")
        }
        .searchable(text: $bookSearchVM.searchString, prompt: "Search Books")
        .overlay {
            if isShowingCheckmark {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundStyle(.thickMaterial)
                    
                    VStack {
                        Image(systemName: isAnimatingCheckmark ? "checkmark.diamond.fill" : "diamond.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.gray)
                            .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                            .task {
                                try? await Task.sleep(for: .milliseconds(100))
                                isAnimatingCheckmark.toggle()
                            }
                        
                        Text("Book Added")
                    }
                    .foregroundStyle(.gray.mix(with: .black, by: 0.2))
                    .padding(40)
                }
                .frame(width: 200, height: 200)
            }
        }
        .onChange(of: isShowingCheckmark) {
            if !isShowingCheckmark {
                isAnimatingCheckmark = false
            }
        }
        .onAppear { updateRankings() }
    }

    private func addItem() {
        withAnimation {
            let newItem = Book(isbn: "9780553897845", ranking: largestRanking + 1)
            largestRanking += 1
            
            let anotherNewItem = Book(isbn: "9780553897876", ranking: largestRanking + 1)
            
            largestRanking += 1
            
            Task {
                do {
                    newItem.details = try await bookInfoService.getBookInfo(isbn: newItem.isbn)
                    anotherNewItem.details = try await bookInfoService.getBookInfo(isbn: anotherNewItem.isbn)
                } catch {
                    print(error)
                }
            }
            
            modelContext.insert(newItem)
            modelContext.insert(anotherNewItem)
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
