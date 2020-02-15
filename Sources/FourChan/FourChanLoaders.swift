#if canImport(Combine)

import Combine
import Foundation

public class Loader<T> : ObservableObject {
  
  public var objectWillChange: AnyPublisher<T?, Never> = Publishers.Sequence<[T?], Never>(sequence: []).eraseToAnyPublisher()
  
  @Published public var data: T? = nil
  
  var cancellable: AnyCancellable?
  
  public init(publisher: AnyPublisher<T, Error>) {
    self.objectWillChange =
      $data.handleEvents(receiveSubscription: { [weak self] sub in
        self?.load(publisher:publisher)
        }, receiveCancel: { [weak self] in
          self?.cancellable?.cancel()
      }).eraseToAnyPublisher()
  }
  
  private func load(publisher: AnyPublisher<T, Error>) {
    if data == nil {
      cancellable =  publisher
        .map { Optional($0) }
        .replaceError(with: nil)
        .receive(on: RunLoop.main)
        .assign(to: \Loader.data, on: self)
    }
  }
  
  deinit {
    cancellable?.cancel()
  }
}

func loader<T: Codable>(endpoint: FourChanAPIEndpoint) -> AnyPublisher<T, Error> {
  URLLoader(url:endpoint.url())
    .decode(type: T.self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
}

/// Top level loader for 4chan.
public class FourChanLoader : Loader<FourChan> {
  
  public init() {
    super.init(publisher:FourChanLoader.fourChanPublisher())
  }
  
  static func fourChanPublisher() -> AnyPublisher<FourChan, Error> {
    loader(endpoint: .boards)
      .tryMap { categorize(boards: $0) }
      .eraseToAnyPublisher()
  }
}

/// Loader for a 4chan catalog.
public class CatalogLoader : Loader<Catalog> {
  public let board: BoardName
  public init(board: BoardName) {
    self.board = board
    super.init(publisher: CatalogLoader.publisher(board: board))
  }
  
  static func publisher(board: BoardName) -> AnyPublisher<Catalog, Error> {
    loader(endpoint: .catalog(board: board))
  }
}

/// Loader for a 4chan thread.
public class ChanThreadLoader : Loader<ChanThread> {
  public let board: BoardName
  public let no: PostNumber
  public init(board: BoardName, no: PostNumber) {
    self.board = board
    self.no = no
    super.init(publisher: ChanThreadLoader.publisher(board:board, no:no))
  }
  
  static func publisher(board: BoardName, no: PostNumber) -> AnyPublisher<ChanThread, Error> {
    loader(endpoint: .thread(board: board, no: no))
  }
}


#endif // canImport(Combine)
