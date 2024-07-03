import Foundation

extension GoogleApiBook {
    struct AccessInfo: Codable {
        var country: String
        var viewability: String
        var embeddable: Bool
        var publicDomain: Bool
        var textToSpeechPermission: String
        var isEpubAvailable: Bool
        var isPdfAvailable: Bool
        var webReaderLink: URL
        var accessViewStatus: String
        var quoteSharingAllowed: Bool
    }
}

extension GoogleApiBook.AccessInfo {
    enum CodingKeys: String, CodingKey {
        case country
        case viewability
        case embeddable
        case publicDomain
        case textToSpeechPermission
        case epub
        case pdf
        case webReaderLink
        case accessViewStatus
        case quoteSharingAllowed
        
        // Custom model keys
        case isEpubAvailable
        case isPdfAvailable
    }
    
    enum NestedCodingKeys: String, CodingKey {
        case isAvailable
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.country = try container.decode(String.self, forKey: .country)
        self.viewability = try container.decode(String.self, forKey: .viewability)
        self.embeddable = try container.decode(Bool.self, forKey: .embeddable)
        self.publicDomain = try container.decode(Bool.self, forKey: .publicDomain)
        self.textToSpeechPermission = try container.decode(String.self, forKey: .textToSpeechPermission)
        self.webReaderLink = try container.decode(URL.self, forKey: .webReaderLink)
        self.accessViewStatus = try container.decode(String.self, forKey: .accessViewStatus)
        self.quoteSharingAllowed = try container.decode(Bool.self, forKey: .quoteSharingAllowed)
        
        if let epubContainer = try? container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .epub) {
            self.isEpubAvailable = try epubContainer.decode(Bool.self, forKey: .isAvailable)
        } else {
            self.isEpubAvailable = try container.decode(Bool.self, forKey: .isEpubAvailable)
        }
        
        if let pdfContainer = try? container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .pdf) {
            self.isPdfAvailable = try pdfContainer.decode(Bool.self, forKey: .isAvailable)
        } else {
            self.isPdfAvailable = try container.decode(Bool.self, forKey: .isPdfAvailable)
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(country, forKey: .country)
        try container.encode(viewability, forKey: .viewability)
        try container.encode(embeddable, forKey: .embeddable)
        try container.encode(publicDomain, forKey: .publicDomain)
        try container.encode(textToSpeechPermission, forKey: .textToSpeechPermission)
        try container.encode(webReaderLink, forKey: .webReaderLink)
        try container.encode(accessViewStatus, forKey: .accessViewStatus)
        try container.encode(quoteSharingAllowed, forKey: .quoteSharingAllowed)
        try container.encode(isEpubAvailable, forKey: .isEpubAvailable)
        try container.encode(isPdfAvailable, forKey: .isPdfAvailable)
    }
}
