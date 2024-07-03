import Foundation

extension GoogleApiBook {
    struct SaleInfo: Codable {
        var country: String
        var saleability: String
        var isEbook: Bool
    }
}
