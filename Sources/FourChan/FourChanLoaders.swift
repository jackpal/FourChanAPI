#if canImport(Combine)

  import Combine
  import Foundation

  public class Loader<T>: ObservableObject {

    public var objectWillChange: AnyPublisher<T?, Never> = Publishers.Sequence<[T?], Never>(
      sequence: []).eraseToAnyPublisher()

    @Published public var data: T? = nil {
      didSet {
        self.loading = false
      }
    }

    /// Interface to triger reloading. Clients set loading to true, which will trigger a reload.
    /// When reloading is complete, loading will be set to false.
    @Published public var loading: Bool = false {
      didSet {
        if oldValue == false && loading == true {
          self.load(publisher: publisher)
        }
      }
    }

    private let publisher: AnyPublisher<T, Error>

    var cancellable: AnyCancellable?

    public init(publisher: AnyPublisher<T, Error>) {
      self.publisher = publisher
      self.objectWillChange =
        $data.handleEvents(
          receiveSubscription: { [weak self] sub in
            self?.load(publisher: publisher)
          },
          receiveCancel: { [weak self] in
            self?.cancellable?.cancel()
          }).eraseToAnyPublisher()
    }

    private func load(publisher: AnyPublisher<T, Error>) {
      cancellable =
        publisher
        .map { Optional($0) }
        .replaceError(with: nil)
        .receive(on: RunLoop.main)
        .assign(to: \Loader.data, on: self)
    }

    deinit {
      cancellable?.cancel()
    }
  }

  func loader<T: Codable>(endpoint: FourChanAPIEndpoint) -> AnyPublisher<T, Error> {
    FourChanService.shared.publisher(endpoint: endpoint)
  }

  /// Top level loader for 4chan.
  public class FourChanLoader: Loader<FourChan> {

    public init() {
      super.init(publisher: FourChanLoader.fourChanPublisher())
    }

    static func fourChanPublisher() -> AnyPublisher<FourChan, Error> {
      loader(endpoint: .boards)
        .tryMap { categorize(boards: $0) }
        .eraseToAnyPublisher()
    }
  }

  /// Loader for a 4chan catalog.
  public class CatalogLoader: Loader<Catalog> {
    public let board: BoardName

    public init(
      board: BoardName,
      publisher: AnyPublisher<Catalog, Error>? = nil
    ) {
      self.board = board
      super.init(publisher: publisher ?? CatalogLoader.publisher(board: board))
    }

    static func publisher(board: BoardName) -> AnyPublisher<Catalog, Error> {
      loader(endpoint: .catalog(board: board))
    }
  }

  /// Loader for a 4chan thread.
  public class ChanThreadLoader: Loader<ChanThread> {
    public let board: BoardName
    public let no: PostNumber

    public init(
      board: BoardName, no: PostNumber,
      publisher: AnyPublisher<ChanThread, Error>? = nil
    ) {
      self.board = board
      self.no = no
      super.init(publisher: publisher ?? ChanThreadLoader.publisher(board: board, no: no))
    }

    static func publisher(board: BoardName, no: PostNumber) -> AnyPublisher<ChanThread, Error> {
      loader(endpoint: .thread(board: board, no: no))
    }
  }

  /// A bring-your-own-publisher loader for PostInContext
  public class PostInContextLoader: Loader<PostInContext> {
    public override init(publisher: AnyPublisher<PostInContext, Error>) {
      super.init(publisher: publisher)
    }
  }

#endif  // canImport(Combine)
