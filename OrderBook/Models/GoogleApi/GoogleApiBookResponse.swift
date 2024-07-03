import Foundation

struct GoogleApiBookResponse: Codable {
    var kind: Kind
    var totalItems: Int
    var items: [GoogleApiBook]
}

extension GoogleApiBookResponse {
    enum Kind: String, Codable {
        case book = "books#volumes"
    }
}

extension Array where Element == GoogleApiBook {
    var bookDetails: [BookDetails] {
        map {
            var photoContainer = CoverPhotoContainer()
            
            if let small = $0.volumeInfo.imageLinks?.smallThumbnail {
                photoContainer.small = .url(small)
            }
            if let medium = $0.volumeInfo.imageLinks?.thumbnail {
                photoContainer.medium = .url(medium)
            }
            
            return BookDetails(
                isbn: $0.volumeInfo.industryIdentifiers?
                    .first(where: { $0.type == .isbn13 })?
                    .identifier ?? "",
                title: $0.volumeInfo.title,
                authors: $0.volumeInfo.authors ?? [],
                desc: $0.volumeInfo.description,
                coverPhoto: photoContainer
            )
        }
    }
}
