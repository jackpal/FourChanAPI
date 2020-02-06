import Foundation

// This is a reverse-engineered, undocumented API that's used for
// the 4chan Mobile API.
// Not sure how stable it is...

public struct FourChanSearchResults: Codable {
  public let body: FourChanSearchResultsBody?
}

public struct FourChanSearchResultsBody: Codable {
  public let board: String?
  public let nhits: Int?
  public let offset: String? // Encoding a decimal integer
  public let query: String?
  public let threads: [FourChanSearchResultsThread]?
}

public struct FourChanSearchResultsThread: Codable, Identifiable {
  public let board: String?
  public let posts: [Post]?
  public let thread: String // "tNNNN" threadID
  
  public var id: String { return thread}
}

public extension FourChanJSONURLs {
  static func search(query:String,
                     offset: Int? = nil,
                     length: Int? = nil,
                     board: String?) -> URL? {
    var components = URLComponents()
     components.scheme = "https"
     components.host = "p.4chan.org"
     components.path = "/api/search"
     components.queryItems = [
         URLQueryItem(name: "q", value: query)
      ]
    if let offset = offset {
      components.queryItems?.append( URLQueryItem(name: "o", value: "\(offset)"))
    }
    if let length = length {
      components.queryItems?.append( URLQueryItem(name: "l", value: "\(length)"))
    }
    if let board = board {
      components.queryItems?.append( URLQueryItem(name: "b", value: board))
    }
    return components.url
  }
}

public extension FourChanSearchResults {
  func filter(_ isIncluded: (FourChanSearchResultsThread) -> Bool) -> FourChanSearchResults {
    FourChanSearchResults(body:
      self.body?.filter(isIncluded))
  }
}

public extension FourChanSearchResultsBody {
  func filter(_ isIncluded: (FourChanSearchResultsThread) -> Bool) -> FourChanSearchResultsBody {
    FourChanSearchResultsBody(
      board: board,
      nhits: nhits,
      offset: offset,
      query: query,
      threads: threads?.filter(isIncluded)
    )
  }
}
