#if canImport(Combine)

import Combine
import Foundation

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

func chanThreadPublisher(board: BoardName, no: PostNumber) -> AnyPublisher<ChanThread, Error> {
  loader(endpoint: .thread(board: board, no: no))
}

func catalogThreadPublisher(board: BoardName) -> AnyPublisher<Catalog, Error> {
  loader(endpoint: .catalog(board: board))
}

public class FourChanLoader : ObservableObject {
  public var objectWillChange: AnyPublisher<FourChan, Never> = Publishers.Sequence<[FourChan], Never>(sequence: []).eraseToAnyPublisher()
  
  @Published public var fourChan: FourChan = FourChan()
  
  var cancellable: AnyCancellable?
  
  public init() {
    self.objectWillChange =
      $fourChan.handleEvents(receiveSubscription: { [weak self] sub in
        self?.load()
        }, receiveCancel: { [weak self] in
          self?.cancellable?.cancel()
      }).eraseToAnyPublisher()
  }
  
  private func load() {
    if fourChan.categories.count == 0 {
      cancellable = fourChanPublisher()
        .receive(on: RunLoop.main)
        .catch {error in
          // TODO: Consider reporting the error.
          Just(FourChan())
      }
      .assign(to: \FourChanLoader.fourChan, on: self)
    }
  }
  
  deinit {
    cancellable?.cancel()
  }
}

public class ChanThreadLoader : ObservableObject {
  public let board: BoardName
  public let no: PostNumber
  
  public var objectWillChange: AnyPublisher<ChanThread, Never> = Publishers.Sequence<[ChanThread], Never>(sequence: []).eraseToAnyPublisher()
  
  @Published public var thread: ChanThread = ChanThread(posts:[])
  
  var cancellable: AnyCancellable?
  
  public init(board: BoardName, no: PostNumber) {
    self.board = board
    self.no = no
    
    self.objectWillChange =
      $thread.handleEvents(receiveSubscription: { [weak self] sub in
        self?.load()
        }, receiveCancel: { [weak self] in
          self?.cancellable?.cancel()
      }).eraseToAnyPublisher()
  }
  
  private func load() {
    if thread.posts.count == 0 {
      cancellable = chanThreadPublisher(board: self.board, no: self.no)
        .receive(on: RunLoop.main)
        .catch {error in
          // TODO: Consider reporting the error.
          Just(ChanThread(posts:[]))
      }
      .assign(to: \ChanThreadLoader.thread, on: self)
    }
  }
  
  deinit {
    cancellable?.cancel()
  }
}

public class CatalogLoader : ObservableObject {
  public let board: BoardName
  
  public var objectWillChange: AnyPublisher<Catalog, Never> = Publishers.Sequence<[Catalog], Never>(sequence: []).eraseToAnyPublisher()
  
  @Published public var catalog: Catalog = Catalog()
  
  var cancellable: AnyCancellable?
  
  public init(board: BoardName) {
    self.board = board
    
    self.objectWillChange =
      $catalog.handleEvents(receiveSubscription: { [weak self] sub in
        self?.load()
        }, receiveCancel: { [weak self] in
          self?.cancellable?.cancel()
      }).eraseToAnyPublisher()
  }
  
  private func load() {
    if catalog.count == 0 {
      cancellable = catalogThreadPublisher(board: self.board)
        .receive(on: RunLoop.main)
        .catch {error in
          // TODO: Consider reporting the error.
          Just(Catalog())
      }
      .assign(to: \CatalogLoader.catalog, on: self)
    }
  }
  
  deinit {
    cancellable?.cancel()
  }
}

#endif // canImport(Combine)
