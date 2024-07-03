import Foundation

extension GoogleApiBook {
    struct VolumeInfo: Codable {
        var title: String
        var subtitle: String?
        var authors: [String]?
        var publisher: String?
        var publishedDate: Date?
        var description: String?
        var industryIdentifiers: [IndustryIdentifiers]?
        var readingModes: ReadingModes
        var pageCount: Int?
        var printType: PrintType
        var categories: [String]?
        var averageRating: Double?
        var ratingsCount: UInt?
        var maturityRating: String
        var allowAnnonLogging: Bool?
        var contentVersion: String
        var imageLinks: ImageLinks?
        var language: String
        var previewLink: URL
        var infoLink: URL
        var canonicalVolumeLink: URL
    }
}

extension GoogleApiBook.VolumeInfo {
    struct IndustryIdentifiers: Codable {
        var type: Kind
        var identifier: String
    }
    
    struct ReadingModes: Codable {
        var text: Bool
        var image: Bool
    }
    
    struct PanelizationSummary: Codable {
        var containsEpubBubbles: Bool
        var containsImageBubbles: Bool
    }
    
    struct ImageLinks: Codable {
        var smallThumbnail: URL
        var thumbnail: URL
    }
    
    enum PrintType: String, Codable {
        case book = "BOOK"
    }
}


extension GoogleApiBook.VolumeInfo.IndustryIdentifiers {
    enum Kind: String, Codable {
        case isbn10 = "ISBN_10"
        case isbn13 = "ISBN_13"
        case issn = "ISSN"
        case other = "OTHER"
    }
}
