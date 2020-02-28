#if canImport(Combine)

  import Combine
  import Foundation

  /// Search using the experimental 4chan mobile search API.
  public func fourChanSearchResultsPublisher(
    board: String? = nil,
    query: String
  ) -> AnyPublisher<FourChanSearchResults, Error> {
    var request = URLRequest(
      url: search(
        query: query, board: board)!
    )
    // Required for the API to return results. Presumably this will
    // need to be updated when the private API changes.
    request.setValue("p4 613fcc6", forHTTPHeaderField: "x-requested-with")
    return URLLoader(urlRequest: request)
      .decode(type: FourChanSearchResults.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }

#endif  // canImport(Combine)
