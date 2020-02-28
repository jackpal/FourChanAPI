import Foundation

/// Endpoints for the 4Chan web site. Useful for sharing browsable URLs.
public enum FourChanWebEndpoint {
  case root
  case catalog(board: BoardName)
  case thread(board: BoardName, thread: Int)
  case post(board: BoardName, thread: Int, post: Int)
}

extension FourChanWebEndpoint {
  func path() -> String {
    switch self {
    case .root:
      return "https://4chan.org/"
    case let .catalog(board):
      return "https://boards.4chan.org/\(board)/catalog"
    case let .thread(board, thread):
      return "https://boards.4chan.org/\(board)/thread/\(thread)"
    case let .post(board, thread, post):
      return "https://boards.4chan.org/\(board)/thread/\(thread)#p\(post)"
    }
  }
}

extension FourChanWebEndpoint {
  public var url: URL {
    return URL(string: path())!
  }
}
