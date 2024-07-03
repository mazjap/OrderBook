import Foundation
import SwiftData

struct CoverPhotoContainer: Codable {
    enum ImageType: Codable {
        case url(URL)
        case data(URL, Data)
    }
    
    var small: ImageType?
    var medium: ImageType?
}

enum ReadingStatus {
    case favorite
    case toRead
    case readingNow
    case haveRead
}

@Model
final class Book {
    var isbn: String
    var details: BookDetails?
    var ranking: UInt
    var dateAdded: Date
    
    init(isbn: String, details: BookDetails? = nil, ranking: UInt, dateAdded: Date = Date()) {
        self.isbn = isbn
        self.details = details
        self.ranking = ranking
        self.dateAdded = dateAdded
    }
}

struct BookDetails: Codable {
    var isbn: String
    var title: String
    var authors: [String]
    var desc: String?
    @Attribute(.externalStorage)
    var coverPhoto: CoverPhotoContainer
}
