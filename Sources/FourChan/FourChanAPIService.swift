import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// This service API was adapted from the github.com/Dimillian/MovieSwiftUI APIService.

public struct FourChanAPIService {
  public static let shared = FourChanAPIService()
  let decoder = JSONDecoder()
  
  public enum APIError: Error {
    case noResponse
    case jsonDecodingError(error: Error)
    case networkError(error: Error)
  }
  
  public enum Endpoint {
    case boards
    case catalog(board: BoardName)
    case thread(board: BoardName, no: PostNumber)
    case threads(board: BoardName, page: PageNumber)
    /// The threads have minimal information filled in.
    case allThreads(board: BoardName)
    case archive(board: BoardName)
    case image(board: BoardName, tim: Int, ext: String)
    case thumbnail(board: BoardName, tim: Int)
    case spoilerImage
    case flag(country: String)
    case polFlag(country: String)
    case search
    
    var path: String {
      switch self {
      case .boards:
        return "https://a.4cdn.org/boards.json"
      case let .catalog(board):
        return "https://a.4cdn.org/\(board)/catalog.json"
      case let .thread(board, no):
        return "https://a.4cdn.org/\(board)/thread/\(no).json"
      case let .threads(board, page):
        return "https://a.4cdn.org/\(board)/\(page).json"
      case let .allThreads(board):
        return "https://a.4cdn.org/\(board)/threads.json"
      case let .archive(board):
        return "https://a.4cdn.org/\(board)/archive.json"
      case let .image(board, tim, ext):
        return "https://i.4cdn.org/\(board)/\(tim)\(ext)"
      case let .thumbnail(board, tim):
        return "https://i.4cdn.org/\(board)/\(tim)s.jpg"
      case .spoilerImage:
        return "https://s.4cdn.org/image/spoiler.png"
      case let .flag(country):
        return "https://s.4cdn.org/image/country/\(country.lowercased()).gif"
      case let .polFlag(country):
        return "https://s.4cdn.org/image/country/troll/\(country).gif"
      case .search:
        return "https://p.4chan.org/api/search"
      }
    }

    public func url(params: [String:String]? = nil) -> URL {
      var components = URLComponents(url: URL(string:path)!, resolvingAgainstBaseURL: true)!
      if let params = params {
        components.queryItems = params.map { (key, value) in
          URLQueryItem(name: key, value: value)
        }
      }
      return components.url!
    }
  }
  
  
  public func GET<T: Codable>(endpoint: Endpoint,
                              params: [String:String]? = nil,
                              completionHandler: @escaping (Result<T, APIError>) -> Void) {
    var request = URLRequest(url:endpoint.url(params: params))
    request.httpMethod = "GET"
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      guard let data = data else {
        DispatchQueue.main.async {
          completionHandler(.failure(.noResponse))
        }
        return
      }
      guard error == nil else {
        DispatchQueue.main.async {
          completionHandler(.failure(.networkError(error: error!)))
        }
        return
      }
      do {
        let object = try self.decoder.decode(T.self, from: data)
        DispatchQueue.main.async {
          completionHandler(.success(object))
        }
      } catch let error {
        DispatchQueue.main.async {
          #if DEBUG
          print("JSON decoding error: \(error)")
          #endif
          completionHandler(.failure(.jsonDecodingError(error: error)))
        }
      }
    }
    task.resume()
  }
}
