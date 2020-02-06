import Combine
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// See https://github.com/4chan/4chan-API

public typealias PostNumber = Int
public typealias BoardName = String
public typealias PageNumber = Int

public typealias Archive = [PostNumber]

public typealias Catalog = [Page]

public struct Board: Codable {
  public let board: BoardName
  public let title: String
  // Worksafe board
  public let ws_board: Int
  public let per_page: Int
  public let pages: Int
  public let max_filesize: Int
  public let max_webm_filesize: Int
  public let max_comment_chars: Int
  public let max_webm_duration: Int
  public let bump_limit: Int
  public let image_limit: Int
  public struct Cooldowns: Codable {
    public let threads: Int
    public let replies: Int
    public let images: Int
  }
  public let cooldowns: Cooldowns
  public let meta_description: String
  public let is_archived: Int?
}

extension Board : Identifiable {
  public var id: String {
    board
  }
}

public struct Boards: Codable {
  public let boards: [Board]
}

public typealias Posts = [Post]

public struct Page : Codable {
  public let page: Int
  public let threads: Posts
}

public typealias Pages = [Page]

/// A message from a user.
public struct Post : Codable {
  /// Post number.
  public let no: PostNumber
  /// Reply to. (Presumably short for "response to")
  public let resto: PostNumber?
  /// Stickied Thread
  public let sticky: Int?
  /// Closed thread
  public let closed: Int?
  /// Archived thread.
  public let archived: Int?
  /// Time when archived. Unix timestamp.
  public let archived_on: Int?
  /// Date and time. MM/DD/YY(Day)HH:MM (:SS on some boards), EST/EDT timezone
  public let now: String?
  /// User name.
  public let name: String?
  /// Tripcode.
  public let trip: String?
  // Conflicts with Identifiable protocol.
  // public let id: String?
  /// Capcode
  public let capcode: String?
  /// Country code. 2 characters ISO 3166-1 alpha-2
  public let country: String?
  /// Country name.
  public let country_name: String?
  /// Subject
  public let sub: String?
  /// Comment. Includes escaped HTML.
  public let com: String?
  /// Renamed filename (for fetching image).
  /// Based on unix timestamp plus milliseconds.
  public let tim: Int?
  /// Original filename.
  public let filename: String?
  /// File extension. .jpg, .png, .gif, .pdf, .swf, .webm
  public let ext: String?
  /// File-size.
  public let fsize: Int?
  /// File MD5.
  public let md5: String?
  /// Image width.
  public let w: Int?
  /// Image height.
  public let h: Int?
  /// Thumbnail width.
  public let tn_w: Int?
  /// Thumbnail height.
  public let tn_h: Int?
  /// File deleted?
  public let filedeleted: Int?
  /// Spoiler image?
  public let spoiler: Int?
  /// Custom spoiler 1-99
  public let custom_spoiler: Int?
  /// Omitted posts.
  public let omitted_posts: Int?
  /// Omitted images.
  public let omitted_images: Int?
  /// Unix timestamp.
  public let time: Int?
  /// Thread URL slug.
  public let semantic_url: String?
  /// Number of unique IPs in thread.
  public let unique_ips: Int?
  public let replies: Int?
  public let images: Int?
  /// Bump limit met?
  public let bumplimit: Int?
  /// Image limit met?
  public let imagelimit: Int?
  // Only displays on /q/, which is not an active board.
  // let capcode_replies
  public let lastReplies: [ChanThread]?
  /// Time when last modified Unix timestamp.
  public let last_modified: Int?
  /// Thread tag.
  /// Only displays on /f/
  public let tag: String?
  /// Year 4chan pass bought.
  public let since4pass: Int?
}

extension Post: Identifiable {
  public var id: Int { return no }
}

// Naming this "Thread" causes SwiftUI previews to fail to compile.
// Error: 'Thread' is ambiguous for type lookup in this context
public struct ChanThread: Codable {
  public let posts: Posts
}

extension ChanThread: Identifiable {
  public var id: Int {
    if posts.count > 0 {
      return posts[0].no
    }
    return 0
  }
}

public typealias ChanThreads = [ChanThread]

public struct Threads : Codable {
  let threads : ChanThreads
}

public enum FourChanJSONURLs {
  public static func boards() -> URL {
    URL(string: "https://a.4cdn.org/boards.json")!
  }
  
  public static func catalog(board: BoardName) -> URL {
    URL(string: "https://a.4cdn.org/\(board)/catalog.json")!
  }
  
  public static func thread(board: BoardName, no: PostNumber) -> URL {
    URL(string: "https://a.4cdn.org/\(board)/thread/\(no).json")!
  }
  
  public static func threads(board: BoardName, page: PageNumber) -> URL {
    URL(string: "https://a.4cdn.org/\(board)/\(page).json")!
  }
  
  /// The threads have minimal information filled in.
  public static func threads(board: BoardName) -> URL {
    URL(string: "https://a.4cdn.org/\(board)/threads.json")!
  }
  
  public static func archive(board: BoardName) -> URL {
    URL(string: "https://a.4cdn.org/\(board)/archive.json")!
  }
  
  public static func image(board: BoardName, tim: Int, ext: String) -> URL {
    URL(string: "https://i.4cdn.org/\(board)/\(tim)\(ext)")!
  }
  
  public static func thumbnail(board: BoardName, tim: Int) -> URL {
    URL(string: "https://i.4cdn.org/\(board)/\(tim)s.jpg")!
  }
  
  public static func spoilerImage() -> URL {
    URL(string: "https://s.4cdn.org/image/spoiler.png")!
  }
  
  public static func flag(country: String) -> URL {
    URL(string:"https://s.4cdn.org/image/country/\(country.lowercased()).gif")!
  }

  public static func polFlag(country: String) -> URL {
    URL(string:"https://s.4cdn.org/image/country/troll/\(country).gif")!
  }
}

public enum FourChanWebURLs {
  public static func rootWebPage() -> URL {
    URL(string: "https://4chan.org/")!
  }
  
  public static func catalogWebPage(board: BoardName) -> URL {
    URL(string: "https://boards.4chan.org/\(board)/catalog" )!
  }
  
  public static func threadWebPage(board: BoardName, thread:Int) -> URL {
    URL(string: "https://boards.4chan.org/\(board)/thread/\(thread)" )!
  }
  
  public static func postWebPage(board: BoardName, thread:Int, post: Int) -> URL {
    URL(string: "https://boards.4chan.org/\(board)/thread/\(thread)#p\(post)" )!
  }

}

public class FourChanService {
  
  public static let shared = FourChanService()
  
  private let session: URLSession
  private let decoder: JSONDecoder
  private let APIRetryCount = 3
  
  init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
    self.session = session
    self.decoder = decoder
  }

  public func boards() -> AnyPublisher<Boards, Error> {
    session.dataTaskPublisher(for: FourChanJSONURLs.boards())
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Boards.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func catalog(board: BoardName) -> AnyPublisher<Catalog, Error> {
    session.dataTaskPublisher(for:
      FourChanJSONURLs.catalog(board:board))
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Catalog.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func thread(board: BoardName, no: PostNumber) -> AnyPublisher<ChanThread, Error> {
    session.dataTaskPublisher(for:
      FourChanJSONURLs.thread(board:board, no: no))
      .map {
        $0.data
      }
      .decode(type: ChanThread.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func threads(board: BoardName, page: PageNumber) -> AnyPublisher<Threads, Error> {
    session.dataTaskPublisher(for:
      FourChanJSONURLs.threads(board: board, page: page))
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Threads.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  // The threads have minimal information filled in.
  public func threads(board: BoardName) -> AnyPublisher<Pages, Error> {
    session.dataTaskPublisher(for:
      FourChanJSONURLs.threads(board: board))
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Pages.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func archive(board: BoardName) -> AnyPublisher<Archive, Error> {
    session.dataTaskPublisher(
      for: FourChanJSONURLs.archive(board: board))
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Archive.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  // Useful for image types that can't decode into UIImage, such as webm and swf.
  public func imageData(board: BoardName, tim: Int, ext: String) -> AnyPublisher<Data, URLError> {
    session.dataTaskPublisher(for:
      FourChanJSONURLs.image(board: board, tim: tim, ext: ext))
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .eraseToAnyPublisher()
  }
}

// TODO: Extend this to watchOS, macOS, tvOS.
#if canImport(UIKit)
public extension FourChanService {
  
  func image(board: BoardName, tim: Int, ext: String) -> AnyPublisher<UIImage, URLError> {
    session.dataTaskPublisher(for:
      FourChanJSONURLs.image(board: board, tim: tim, ext: ext))
      .retry(APIRetryCount)
      .map { $0.data }
      .compactMap(UIImage.init(data:))
      .eraseToAnyPublisher()
  }

  func thumbnail(board: BoardName, tim: Int) -> AnyPublisher<UIImage, URLError> {
    session.dataTaskPublisher(for:
      FourChanJSONURLs.thumbnail(board: board, tim: tim))
      .retry(APIRetryCount)
      .map { $0.data }
      .compactMap(UIImage.init(data:))
      .eraseToAnyPublisher()
  }
}
#endif

public extension FourChanService {
  typealias PostWithContext = (post: Post, boardName: String)
  
  func allPosts() -> AnyPublisher<PostWithContext, Never> {
    typealias PagesWithContext = (pages: Pages, boardName: BoardName)

    return boards()
    .assertNoFailure()
    .flatMap {
      Publishers.Sequence<[Board], Never>(sequence: $0.boards)
    }
    .flatMap { (board: Board) -> AnyPublisher<PagesWithContext, Never> in
      let boardName = board.board
      return self.threads(board:boardName)
      .assertNoFailure()
      .map {
        // Return a tuple of board and result in order to pass the
        // board down to the subsequent thread call.
        (pages:$0, boardName:boardName)
      }
      .eraseToAnyPublisher()
    }
    .flatMap { pagesWithContext in
      Publishers.Sequence<[Page], Never>(sequence: pagesWithContext.pages)
      .map {
        (page:$0, boardName:pagesWithContext.boardName)
      }
    }
    .flatMap { pageWithContext in
      Publishers.Sequence<[Post], Never>(sequence: pageWithContext.page.threads)
      .map {
        (post: $0, boardName: pageWithContext.boardName)
      }
    }
    .flatMap { postWithContext in
      self.thread(board:postWithContext.boardName, no:postWithContext.post.no)
      .assertNoFailure()
      .map {
        (thread: $0, boardName: postWithContext.boardName)
      }
    }
    .flatMap { threadWithContext in
      Publishers.Sequence<Posts, Never>(sequence: threadWithContext.thread.posts)
      .map {
        (post: $0, boardName: threadWithContext.boardName)
      }
    }
    .eraseToAnyPublisher()
  }
}

public extension String {
  var clean: String {
    self
      .replacingOccurrences(of: "&#039;", with: "'")
      .replacingOccurrences(of: "&#044;", with: ",")
      .replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "<br>", with: "\n")
      .replacingOccurrences(of: "<wbr>", with: "\u{200b}")
  }
}

