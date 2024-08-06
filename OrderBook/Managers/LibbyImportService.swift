import Foundation

enum LibbyImportError: Error {
    case fileNotFound
    case other(Error)
}

final class LibbyImportService: Sendable {
    func importFile(named name: String, type: String) throws(LibbyImportError) -> [BookDetails] {
        guard let url = Bundle.main.url(forResource: name, withExtension: type),
              let data = try? Data(contentsOf: url)
        else {
            throw .fileNotFound
        }
        
        let decoder = JSONDecoder()
        
        do {
            let libbyImport = try decoder.decode(LibbyImport.self, from: data)
            
            return libbyImport.timeline.map { entry in
                return BookDetails(
                    isbn: entry.isbn,
                    title: entry.title.text,
                    authors: [entry.author],
                    coverPhoto: CoverPhotoContainer(small: nil, medium: .url(entry.cover.url))
                )
            }
        } catch {
            throw .other(error)
        }
    }
}
