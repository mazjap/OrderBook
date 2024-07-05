import Foundation
import UIKit.UIImage

enum BookInfoError: Error {
    case badURL
    case noData
    case badConversion
    case badDecode(Error)
    case badResponse(code: Int?)
    case other(Error)
}

final class BookInfoService: Sendable {
    enum BookCoverSize: String {
        case small = "S"
        case medium = "M"
        case large = "L"
    }
    
    private let coverApi = "https://covers.openlibrary.org/b/isbn/"
    private let searchApi = "https://www.googleapis.com/books/v1/"
    
    func getBookInfo(isbn: String) async throws(BookInfoError) -> BookDetails {
        guard let details = try await getBookInfos(for: "isbn:\(isbn)").first else { throw .noData }
        
        return details
    }
    
    func getBookInfos(for searchTerm: String) async throws(BookInfoError) -> [BookDetails] {
        guard let querylessUrl = URL(string: searchApi)?.appending(path: "volumes") else {
            throw .badURL
        }
        
        var components = URLComponents(url: querylessUrl, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "q", value: searchTerm)
        ]
        
        guard let url = components?.url else {
            throw .badURL
        }
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        var data: Data?
        
        do {
            let (resData, response) = try await URLSession.shared.data(for: request)
            
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                throw BookInfoError.badResponse(code: response.statusCode)
            }
            
            data = resData
        } catch BookInfoError.badResponse(let code) {
            throw .badResponse(code: code)
        } catch {
            throw .other(error)
        }
        
        guard let data else { throw .noData }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            if let date = Self.yearMonthDayFormatter.date(from: dateStr) ??
                          Self.yearOnlyFormatter.date(from: dateStr) ??
                          Self.iso8601Formatter.date(from: dateStr) ??
                          Self.yearMonthOnlyFormatter.date(from: dateStr) {
                return date
            } else {
                throw DecodingError.typeMismatch(Date.self, .init(codingPath: decoder.codingPath, debugDescription: "date is not iso8601, year only, nor year-month-day. Value: \(dateStr)"))
            }
        }
        
        do {
            let googleResponse = try decoder.decode(GoogleApiBookResponse.self, from: data)
            return googleResponse.items.bookDetails
        } catch {
            #if DEBUG
                print("Data string where decoding failed:")
                print(String(data: data, encoding: .utf8) ?? "")
            #endif
            throw .badDecode(error)
        }
    }
    
    func getCover(for isbn: String, size: BookCoverSize) async throws(BookInfoError) -> UIImage {
        guard let url = URL(string: coverApi + "\(isbn)-\(size.rawValue)") else {
            throw .badURL
        }
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        
        var data: Data?
        
        do {
            let (resData, response) = try await URLSession.shared.data(for: request)
            
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                throw BookInfoError.badResponse(code: response.statusCode)
            }
            
            data = resData
        } catch BookInfoError.badResponse(let code) {
            throw .badResponse(code: code)
        } catch {
            throw .other(error)
        }
        
        guard let data else { throw .noData }
        guard let image = UIImage(data: data) else { throw .badConversion }
        
        return image
    }
    
    static nonisolated(unsafe) private let iso8601Formatter = ISO8601DateFormatter()
    static private let yearOnlyFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy"
        
        return dateFormatter
    }()
    static private let yearMonthDayFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter
    }()
    static private let yearMonthOnlyFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM"
        
        return dateFormatter
    }()
}
