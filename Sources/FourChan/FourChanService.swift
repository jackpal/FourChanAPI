#if canImport(Combine)

  import Combine
  import Foundation

  /// The FourChan API exposed as Combine Publishers.
  public struct FourChanService {

    public static let shared = FourChanService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let APIRetryCount = 3

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
      self.session = session
      self.decoder = decoder
    }

    public func dataPublisher(endpoint: FourChanAPIEndpoint) -> AnyPublisher<Data, Error> {
      session.dataTaskPublisher(for: endpoint.url())
        .retry(APIRetryCount)
        .map { $0.data }
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    public func publisher<T: Codable>(endpoint: FourChanAPIEndpoint) -> AnyPublisher<T, Error> {
      dataPublisher(endpoint: endpoint)
        .decode(type: T.self, decoder: decoder)
        .eraseToAnyPublisher()
    }

    public func boards() -> AnyPublisher<Boards, Error> {
      publisher(endpoint: .boards)
    }

    public func catalog(board: BoardName) -> AnyPublisher<Catalog, Error> {
      publisher(endpoint: .catalog(board: board))
    }

    public func thread(board: BoardName, no: PostNumber) -> AnyPublisher<ChanThread, Error> {
      publisher(endpoint: .thread(board: board, no: no))
    }

    public func threads(board: BoardName, page: PageNumber) -> AnyPublisher<Threads, Error> {
      publisher(endpoint: .threads(board: board, page: page))
    }

    /// The threads have minimal information filled in.
    public func threads(board: BoardName) -> AnyPublisher<Pages, Error> {
      publisher(endpoint: .allThreads(board: board))
    }

    public func archive(board: BoardName) -> AnyPublisher<Archive, Error> {
      publisher(endpoint: .archive(board: board))
    }

    /// Useful for image types that can't decode into UIImage, such as webm and swf.
    public func imageData(board: BoardName, tim: Int, ext: String) -> AnyPublisher<Data, Error> {
      publisher(endpoint: .image(board: board, tim: tim, ext: ext))
    }
  }

  // TODO: Extend this to watchOS, macOS, tvOS.
  #if canImport(UIKit)

    import UIKit

    extension FourChanService {

      public func publisher(endpoint: FourChanAPIEndpoint) -> AnyPublisher<UIImage, Error> {
        publisher(endpoint: endpoint)
        .compactMap(UIImage.init(data:))
        .eraseToAnyPublisher()
      }

      public func image(board: BoardName, tim: Int, ext: String) -> AnyPublisher<UIImage, Error> {
        publisher(endpoint: .image(board: board, tim: tim, ext: ext))
      }

      public func thumbnail(board: BoardName, tim: Int) -> AnyPublisher<UIImage, Error> {
        publisher(endpoint: .thumbnail(board: board, tim: tim))
      }

    }

  #endif

  extension FourChanService {
    /**
    Returns a publisher of all posts.
   */
    public func posts() -> AnyPublisher<PostInContext, Error> {
      boards()
        .flatMap(maxPublishers: .max(1)) { boards in
          Publishers.Sequence<[Board], Error>(sequence: boards.boards)
            .flatMap(maxPublishers: .max(1)) { board in
              self.posts(board: board.board)
            }
        }.eraseToAnyPublisher()
    }

    /**
   Returns a publisher of all posts in a given board.
   */
    public func posts(board: BoardName) -> AnyPublisher<PostInContext, Error> {
      threads(board: board)
        .flatMap(maxPublishers: .max(1)) { pages in
          Publishers.Sequence<[Page], Error>(sequence: pages)
            .flatMap(maxPublishers: .max(1)) { page in
              Publishers.Sequence<[Post], Error>(sequence: page.threads)
                .flatMap(maxPublishers: .max(1)) { post in
                  self.posts(board: board, no: post.no)
                }
            }
        }.eraseToAnyPublisher()
    }

    /**
   Returns a publisher of all posts in a given thread, identified by board name and post number.
   */
    public func posts(board: BoardName, no: PostNumber) -> AnyPublisher<PostInContext, Error> {
      thread(board: board, no: no)
        .flatMap(maxPublishers: .max(1)) { chanThread in
          Publishers.Sequence<Posts, Error>(sequence: chanThread.posts)
            .map {
              PostInContext(
                board: board,
                thread: no,
                post: $0)
            }
        }
        .eraseToAnyPublisher()
    }
  }

#endif
