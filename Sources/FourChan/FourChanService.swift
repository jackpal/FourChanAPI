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

  public func boards() -> AnyPublisher<Boards, Error> {
    session.dataTaskPublisher(for: FourChanAPIService.Endpoint.boards.url())
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Boards.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func catalog(board: BoardName) -> AnyPublisher<Catalog, Error> {
    session.dataTaskPublisher(for:
      FourChanAPIService.Endpoint.catalog(board:board).url())
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Catalog.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func thread(board: BoardName, no: PostNumber) -> AnyPublisher<ChanThread, Error> {
    session.dataTaskPublisher(for:
      FourChanAPIService.Endpoint.thread(board:board, no: no).url())
      .map {
        $0.data
      }
      .decode(type: ChanThread.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func threads(board: BoardName, page: PageNumber) -> AnyPublisher<Threads, Error> {
    session.dataTaskPublisher(for:
      FourChanAPIService.Endpoint.threads(board: board, page: page).url())
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
      FourChanAPIService.Endpoint.allThreads(board: board).url())
      .retry(APIRetryCount)
      .map {
        $0.data
      }
      .decode(type: Pages.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  public func archive(board: BoardName) -> AnyPublisher<Archive, Error> {
    session.dataTaskPublisher(
      for: FourChanAPIService.Endpoint.archive(board: board).url())
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
      FourChanAPIService.Endpoint.image(board: board, tim: tim, ext: ext).url())
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
      FourChanAPIService.Endpoint.image(board: board, tim: tim, ext: ext).url())
      .retry(APIRetryCount)
      .map { $0.data }
      .compactMap(UIImage.init(data:))
      .eraseToAnyPublisher()
  }

  func thumbnail(board: BoardName, tim: Int) -> AnyPublisher<UIImage, URLError> {
    session.dataTaskPublisher(for:
      FourChanAPIService.Endpoint.thumbnail(board: board, tim: tim).url())
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

#endif
