import SwiftUI
import SwiftData

enum SelectableTab {
    case toBeRead
    case readBooks
    case favorites
//    case settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = SelectableTab.toBeRead
    
    var body: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                tabChildren
            }
        } else {
            TabView(selection: $selectedTab) {
                pre18TabChildren
            }
        }
    }
    
    @available(iOS 18.0, *)
    @TabContentBuilder<SelectableTab>
    private var tabChildren: some TabContent<SelectableTab> {
        Tab("To Be Read", systemImage: "book", value: .toBeRead) {
            toBeReadContent
        }
        
        Tab("Read Books", systemImage: "books.vertical", value: .readBooks) {
            readBooksContent
        }
        
        Tab("Favorites", systemImage: "star", value: .favorites) {
            favoritesContent
        }
    }
    
    @ViewBuilder
    private var pre18TabChildren: some View {
        toBeReadContent
            .tabItem {
                Label("To Be Read", systemImage: "book")
            }
            .tag(SelectableTab.toBeRead)
        
        readBooksContent
            .tabItem {
                Label("Previously Read", systemImage: "books.vertical")
            }
            .tag(SelectableTab.readBooks)
        
        favoritesContent
            .tabItem {
                Label("Favorites", systemImage: "star")
            }
            .tag(SelectableTab.favorites)
    }
    
    private var toBeReadContent: some View {
        NavigationStack {
            ToBeRead()
        }
    }
    
    private var readBooksContent: some View {
        NavigationStack {
            ReadBooks()
        }
    }
    
    private var favoritesContent: some View {
        NavigationStack {
            Favorites()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
