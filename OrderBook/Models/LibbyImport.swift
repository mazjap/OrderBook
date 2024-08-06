import Foundation

struct LibbyImport: Codable {
    var version: Int
    var timeline: [Entry]
}

extension LibbyImport {
    struct Entry: Codable {
        var cover: Cover
        var title: Title
        var author: String
        var publisher: String
        var isbn: String
        var timestamp: Int
        var activity: String
        var library: Library
    }
}

extension LibbyImport.Entry {
    struct Cover: Codable {
        var contentType: String
        var url: URL
        var title: String
        var color: String
        var format: String
    }
    
    struct Title: Codable {
        var text: String
        var url: URL
        var titleId: String
    }
    
    struct Library: Codable {
        var text: String
        var url: URL
        var key: String
    }
}
