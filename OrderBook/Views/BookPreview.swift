import SwiftUI

fileprivate enum ImageProvider {
    case uiImage(UIImage)
    case url(URL)
    case placeholder
}

struct BookPreview: View {
    private let book: BookDetails
    private let isFavorite: Bool
    private let rank: UInt?
    
    init(book: BookDetails, isFavorite: Bool = false, rank: UInt? = nil) {
        self.book = book
        self.isFavorite = isFavorite
        self.rank = rank
    }
    
    private var imageProvider: ImageProvider {
        guard let smallImageType = book.coverPhoto.small else { return .placeholder }
        
        switch smallImageType {
        case let .data(url, data):
            guard let uiImage = UIImage(data: data) else { return .url(url) }
            return .uiImage(uiImage)
        case let .url(url):
            return .url(url)
        }
    }
    
    private var placeholderImage: some View {
        Image("placeholder")
            .resizable()
            .scaledToFit()
    }
    
    var body: some View {
        HStack {
            Group {
                switch imageProvider {
                case let .uiImage(uiImage):
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                case let .url(url):
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image.resizable()
                                .scaledToFit()
                        case .empty:
                            placeholderImage
                        case .failure(let error):
                            placeholderImage
                                .onAppear {
                                    print(error)
                                }
                        @unknown default:
                            fatalError("Handle other async image case")
                        }
                    }
                case .placeholder:
                    Image("placeholder")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(maxWidth: 80, maxHeight: 100)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(book.title)
                        .font(.title3)
                        .lineLimit(3)
                    
                    Spacer()
                    
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.headline)
                    }
                    
                    if let rank {
                        Text("\(rank)")
                            .font(.title2)
                    }
                }
                
                Text(book.authors.joined(separator: ", "))
                    .font(.caption)
                    .lineLimit(1)
                
                if let desc = book.desc {
                    Text(desc)
                        .font(.caption2)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    var photoContainer = CoverPhotoContainer()
    
    if let url = URL(string: "http://books.google.com/books/content?id=5NomkK4EV68C&printsec=frontcover&img=1&zoom=5&edge=curl&source=gbs_api") {
        photoContainer.small = .url(url)
    }
    
    return BookPreview(
        book: BookDetails(
            isbn: "9780553897845",
            title: "A Game of Thrones",
            authors: ["George R. R. Martin"],
            desc: "A really long description of GRRM's `A Game of Thrones`, released in 1997 or smth, to critical acclaim and later adapted to a TV show",
            coverPhoto: photoContainer
        ),
        isFavorite: true,
        rank: 1
    )
}
