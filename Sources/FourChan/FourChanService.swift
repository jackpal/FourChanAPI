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
  /**
    Returns a publisher that iterates through all currently published posts.
    
    Not super practical, just for fun.
   */
  func posts() -> AnyPublisher<PostInContext, Error> {
    boards()
    .flatMap { boards in
      Publishers.Sequence<[Board], Error>(sequence: boards.boards)
        .flatMap { board in
          self.posts(board:board.board)
      }
    }.eraseToAnyPublisher()
  }
  
  /**
   Returns a publisher of all posts in a given board.
   */
  func posts(board: BoardName) -> AnyPublisher<PostInContext, Error> {
    threads(board:board)
      .flatMap { pages in
        Publishers.Sequence<[Page], Error>(sequence: pages)
          .flatMap { page in
            Publishers.Sequence<[Post], Error>(sequence: page.threads)
              .flatMap { post in
                self.posts(board:board, no:post.no)
            }
        }
    }.eraseToAnyPublisher()
  }
  
  /**
   Returns a publisher of all posts in a given thread, identified by board name and post number.
   */
  func posts(board: BoardName, no:PostNumber) -> AnyPublisher<PostInContext, Error> {
    thread(board:board, no:no)
    .flatMap { chanThread in
      Publishers.Sequence<Posts, Error>(sequence: chanThread.posts)
      .map {
        PostInContext(board: board,
                      thread: no,
                      post: $0)
      }
    }
    .eraseToAnyPublisher()
  }
}

#endif
