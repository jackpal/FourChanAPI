import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A completion-handler-based API.
///
/// This service API was adapted from the github.com/Dimillian/MovieSwiftUI APIService.
public struct FourChanAPIService {
  public static let shared = FourChanAPIService()
  let decoder = JSONDecoder()

  public enum APIError: Error {
    case noResponse
    case jsonDecodingError(error: Error)
    case networkError(error: Error)
  }

  public func GET<T: Codable>(
    endpoint: FourChanAPIEndpoint,
    params: [String: String]? = nil,
    completionHandler: @escaping (Result<T, APIError>) -> Void
  ) {
    var request = URLRequest(url: endpoint.url(params: params))
    request.httpMethod = "GET"
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      guard let data = data else {
        DispatchQueue.main.async {
          completionHandler(.failure(.noResponse))
        }
        return
      }
      guard error == nil else {
        DispatchQueue.main.async {
          completionHandler(.failure(.networkError(error: error!)))
        }
        return
      }
      do {
        let object = try self.decoder.decode(T.self, from: data)
        DispatchQueue.main.async {
          completionHandler(.success(object))
        }
      } catch let error {
        DispatchQueue.main.async {
          #if DEBUG
            print("JSON decoding error: \(error)")
          #endif
          completionHandler(.failure(.jsonDecodingError(error: error)))
        }
      }
    }
    task.resume()
  }
}
