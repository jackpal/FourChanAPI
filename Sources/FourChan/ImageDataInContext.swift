#if canImport(Combine)

  import Combine
  import Foundation

  public struct ImageDataInContext {
    public let post: PostInContext
    public let imageData: Data

    public init(post: PostInContext, imageData: Data) {
      self.post = post
      self.imageData = imageData
    }

  }

  extension Publisher where Self.Output == PostInContext, Self.Failure == Error {

    /// Posts that have images.
    public func imagePosts() -> AnyPublisher<PostInContext, Error> {
      self.filter { $0.image != nil }.eraseToAnyPublisher()
    }

    /// All images from a publisher of PostInContexts.
    public func imageDatas() -> AnyPublisher<ImageDataInContext, Error> {
      self
        .imagePosts()
        // max(1) avoids trying to fetch all the images at once.
        .flatMap(maxPublishers: .max(1)) { post in
          FourChanService.shared.dataPublisher(endpoint: post.image!)
            .map {
              ImageDataInContext(post: post, imageData: $0)
            }
        }
        .eraseToAnyPublisher()
    }

  }

#endif
