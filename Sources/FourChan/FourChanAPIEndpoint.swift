import Foundation

/// The endpoints that make up the read-only 4chan API.
///
/// See https://github.com/4chan/4chan-API
public enum FourChanAPIEndpoint {
  case boards
  case catalog(board: BoardName)
  case thread(board: BoardName, no: PostNumber)
  case threads(board: BoardName, page: PageNumber)

  /// The threads have minimal information filled in.
  case allThreads(board: BoardName)

  case archive(board: BoardName)
  case image(board: BoardName, tim: ImageNumber, ext: String)
  case thumbnail(board: BoardName, tim: ImageNumber)
  case spoilerImage
  case flag(country: String)
  case polFlag(country: String)
  case boardFlag(board: BoardName, code: String)
  case customSpoiler(board: BoardName, index: Int)

  /// Mobile Search endpoint. Takes additional query parameters.
  case search
}

extension FourChanAPIEndpoint {
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
    case let .boardFlag(board, code):
      return "https://s.4cdn.org/image/flags/\(board)/\(code).gif"
    case let .customSpoiler(board, index):
      return "https://s.4cdn.org/image/spoiler-\(board)\(index).png"
    case .search:
      return "https://p.4chan.org/api/search"
    }
  }
}

extension FourChanAPIEndpoint {
  public func url(params: [String: String]? = nil) -> URL {
    var components = URLComponents(url: URL(string: path)!, resolvingAgainstBaseURL: true)!
    if let params = params {
      components.queryItems = params.map { (key, value) in
        URLQueryItem(name: key, value: value)
      }
    }
    return components.url!
  }
}
