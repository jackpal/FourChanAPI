import Foundation

/// This is a reverse-engineered, undocumented API that's used for
/// the 4chan Mobile API.
/// Not sure how stable it is...
public struct FourChanSearchResults: Codable {
  public let body: FourChanSearchResultsBody?
}

public struct FourChanSearchResultsBody: Codable {
  public let board: String?
  public let nhits: Int?
  public let offset: String?  // Encoding a decimal integer
  public let query: String?

  public let threads: [FourChanSearchResultsThread]?
}

public struct FourChanSearchResultsThread: Codable, Identifiable {
  public let board: String?
  public let posts: [Post]?
  public let thread: String  // "tNNNN" threadID

  public var id: String { return thread }
}

func search(
  query: String,
  offset: Int? = nil,
  length: Int? = nil,
  board: String?
) -> URL? {
  var params = ["q": query]
  if let offset = offset {
    params["o"] = "\(offset)"
  }
  if let length = length {
    params["l"] = "\(length)"
  }
  if let board = board {
    params["b"] = board
  }
  return FourChanAPIEndpoint.search.url(params: params)
}

extension FourChanSearchResults {
  public func filter(_ isIncluded: (FourChanSearchResultsThread) -> Bool) -> FourChanSearchResults {
    FourChanSearchResults(
      body:
        self.body?.filter(isIncluded))
  }
}

extension FourChanSearchResultsBody {
  public func filter(_ isIncluded: (FourChanSearchResultsThread) -> Bool)
    -> FourChanSearchResultsBody
  {
    FourChanSearchResultsBody(
      board: board,
      nhits: nhits,
      offset: offset,
      query: query,
      threads: threads?.filter(isIncluded)
    )
  }
}
