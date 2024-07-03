import Foundation

struct GoogleApiBook: Codable {
    var kind: Kind
    var id: String
    var etag: String
    var selfLink: URL
    var volumeInfo: VolumeInfo
    var saleInfo: SaleInfo?
    var accessInfo: AccessInfo?
    var searchInfo: SearchInfo?
}

extension GoogleApiBook {
    struct SearchInfo: Codable {
        var textSnippet: String
    }
    
    enum Kind: String, Codable {
        case book = "books#volume"
    }
}
