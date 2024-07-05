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

enum ReadingStatus: UInt8, Codable {
    case toRead
    case readingNow
    case alreadyRead
    
    var hasRead: Bool {
        if case .alreadyRead = self {
            return true
        }
        
        return false
    }
}

@Model
final class Book {
    var isbn: String
    var details: BookDetails?
    var ranking: UInt
    var favoriteRanking: UInt
    var statusValue: UInt8
    var isFavorite: Bool
    var dateAdded: Date
    var dateRead: Date?
    
    var status: ReadingStatus {
        get {
            ReadingStatus(rawValue: statusValue) ?? .toRead
        }
        set {
            statusValue = newValue.rawValue
        }
    }
    
    init(isbn: String, details: BookDetails? = nil, ranking: UInt, favoriteRanking: UInt = .max, status: ReadingStatus = .toRead, isFavorite: Bool = false, dateAdded: Date = Date(), dateRead: Date? = nil) {
        self.isbn = isbn
        self.details = details
        self.ranking = ranking
        self.favoriteRanking = favoriteRanking
        self.statusValue = status.rawValue
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.dateRead = dateRead
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
