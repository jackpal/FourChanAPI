import Foundation

public typealias PostFilter = (Post) -> Bool

extension Catalog {
  public func filterShouldBeShown(postFilter: PostFilter) -> Catalog {
    self.map {
      $0.filterShouldBeShown(postFilter: postFilter)
    }
  }
}

extension ChanThread {
  public func filterShouldBeShown(postFilter: PostFilter) -> ChanThread {
    ChanThread(posts: posts.filterShouldBeShown(postFilter: postFilter))
  }
}

extension Page {
  public func filterShouldBeShown(postFilter: PostFilter) -> Page {
    Page(page: page, threads: threads.filterShouldBeShown(postFilter: postFilter))
  }
}

extension Posts {
  public func filterShouldBeShown(postFilter: PostFilter) -> Posts {
    self.filter {
      postFilter($0)
    }
  }
}

extension Post {
  public func hasReasonableSizedImage() -> Bool {
    // Filter out tiny images.
    tim != nil && (w ?? 0) >= 32 && (h ?? 0) >= 32
  }
}

extension String {
  public func isReadableImageType() -> Bool {
    return renderableImageExtension(ext: self)
  }
}

public func renderableImageExtension(ext: String) -> Bool {
  switch ext {
  case ".gif":
    return true
  case ".jpg":
    return true
  case ".png":
    return true
  default:
    return false
  }
}
