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

func fourChanPublisher() -> AnyPublisher<FourChan, Error> {
  loader(endpoint: .boards)
    .tryMap { categorize(boards: $0) }
    .eraseToAnyPublisher()
}


public class FourChanLoader : Loader<FourChan> {
  public init() {
    super.init(publisher:fourChanPublisher())
  }
}

public class ChanThreadLoader : Loader<ChanThread> {
  public init(board: BoardName, no: PostNumber) {
    super.init(publisher: loader(endpoint: .thread(board: board, no: no)))
  }
}

public class CatalogLoader : Loader<Catalog> {
  public init(board: BoardName) {
    super.init(publisher: loader(endpoint: .catalog(board: board)))
  }
}

#endif // canImport(Combine)
