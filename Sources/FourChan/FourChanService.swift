#if canImport(Combine)

import Combine

#if canImport(UIKit)
import UIKit
#endif

public class FourChanService {
  
  public static let shared = FourChanService()
  
  private let session: URLSession
  private let decoder: JSONDecoder
  private let APIRetryCount = 3
  
  init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
    self.session = session
    self.decoder = decoder
  }
  
  public func publisher<T: Codable>(endpoint: FourChanAPIEndpoint) -> AnyPublisher<T, Error> {
    session.dataTaskPublisher(for: endpoint.url())
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: T.self, decoder: decoder)
      .eraseToAnyPublisher()
  }

  public func boards() -> AnyPublisher<Boards, Error> {
    publisher(endpoint:.boards)
  }
  
  public func catalog(board: BoardName) -> AnyPublisher<Catalog, Error> {
     publisher(endpoint:.catalog(board:board))
  }
  
  public func thread(board: BoardName, no: PostNumber) -> AnyPublisher<ChanThread, Error> {
    publisher(endpoint:.thread(board:board, no: no))
  }
  
  public func threads(board: BoardName, page: PageNumber) -> AnyPublisher<Threads, Error> {
    publisher(endpoint:.threads(board: board, page: page))
  }
  
  // The threads have minimal information filled in.
  public func threads(board: BoardName) -> AnyPublisher<Pages, Error> {
    publisher(endpoint:.allThreads(board: board))
  }
  
  public func archive(board: BoardName) -> AnyPublisher<Archive, Error> {
    publisher(endpoint:.archive(board: board))
  }
  
  // Useful for image types that can't decode into UIImage, such as webm and swf.
  public func imageData(board: BoardName, tim: Int, ext: String) -> AnyPublisher<Data, Error> {
    publisher(endpoint:.image(board: board, tim: tim, ext: ext))
  }
}

// TODO: Extend this to watchOS, macOS, tvOS.
#if canImport(UIKit)
public extension FourChanService {
  
  func publisher(endpoint: FourChanAPIEndpoint) -> AnyPublisher<UIImage, Error> {
    publisher(endpoint:endpoint)
    .compactMap(UIImage.init(data:))
    .eraseToAnyPublisher()
  }
  
  func image(board: BoardName, tim: Int, ext: String) -> AnyPublisher<UIImage, Error> {
    publisher(endpoint:.image(board:board, tim:tim, ext:ext))
  }

  func thumbnail(board: BoardName, tim: Int) -> AnyPublisher<UIImage, Error> {
    publisher(endpoint:.thumbnail(board: board, tim: tim))
  }
}
#endif

public extension FourChanService {
  typealias PostWithContext = (post: Post, boardName: String)
  
  func allPosts() -> AnyPublisher<PostWithContext, Error> {
    typealias PagesWithContext = (pages: Pages, boardName: BoardName)

    return boards()
    .flatMap {
      Publishers.Sequence<[Board], Error>(sequence: $0.boards)
    }
    .flatMap { (board: Board) -> AnyPublisher<PagesWithContext, Error> in
      let boardName = board.board
      return self.threads(board:boardName)
      .map {
        // Return a tuple of board and result in order to pass the
        // board down to the subsequent thread call.
        (pages:$0, boardName:boardName)
      }
      .eraseToAnyPublisher()
    }
    .flatMap { pagesWithContext in
      Publishers.Sequence<[Page], Error>(sequence: pagesWithContext.pages)
      .map {
        (page:$0, boardName:pagesWithContext.boardName)
      }
    }
    .flatMap { pageWithContext in
      Publishers.Sequence<[Post], Error>(sequence: pageWithContext.page.threads)
      .map {
        (post: $0, boardName: pageWithContext.boardName)
      }
    }
    .flatMap { postWithContext in
      self.thread(board:postWithContext.boardName, no:postWithContext.post.no)
      .map {
        (thread: $0, boardName: postWithContext.boardName)
      }
    }
    .flatMap { threadWithContext in
      Publishers.Sequence<Posts, Error>(sequence: threadWithContext.thread.posts)
      .map {
        (post: $0, boardName: threadWithContext.boardName)
      }
    }
    .eraseToAnyPublisher()
  }
}

#endif
