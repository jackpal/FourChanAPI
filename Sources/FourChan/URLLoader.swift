#if canImport(Combine)

  import Combine
  import Foundation

  fileprivate var dataCache = Cache<URL, Data>(maximumEntryCount: 50)

  /// Returns a publisher for a URL. Caches and retries errors.
  public func URLLoader(url: URL) -> AnyPublisher<Data, Error> {
    URLLoader(urlRequest: URLRequest(url: url))
  }

  /// Returns a publisher for a URLRequest. Caches and retries errors.
  public func URLLoader(urlRequest: URLRequest) -> AnyPublisher<Data, Error> {
    if let data = dataCache[urlRequest.url!] {
      let simplePublisher = CurrentValueSubject<Data, Error>(data)
      return simplePublisher.eraseToAnyPublisher()
    } else {
      return URLSession.shared.dataTaskPublisher(for: urlRequest)
        .retry(3)
        .tryMap { (data, response) -> Data in
          dataCache[urlRequest.url!] = data
          return data
        }
        .eraseToAnyPublisher()
    }
  }

#endif
