import Foundation

public typealias PostFilter = (Post) -> Bool

public extension Catalog {
  func filterShouldBeShown(postFilter: PostFilter) -> Catalog {
    self.map {
        $0.filterShouldBeShown(postFilter:postFilter)
    }
  }
}

public extension ChanThread {
  func filterShouldBeShown(postFilter: PostFilter) -> ChanThread {
    ChanThread(posts: posts.filterShouldBeShown(postFilter:postFilter))
  }
}

public extension Page {
  func filterShouldBeShown(postFilter: PostFilter) -> Page {
    Page(page:page, threads: threads.filterShouldBeShown(postFilter:postFilter))
  }
}

public extension Posts {
  func filterShouldBeShown(postFilter: PostFilter) -> Posts {
    self.filter {
      postFilter($0)
    }
  }
}

public extension Post {
  func hasReasonableSizedImage() -> Bool {
    // Filter out tiny images.
    tim != nil && (w ?? 0) >= 32 && (h ?? 0) >= 32
  }
}

public extension String {
  func isReadableImageType() -> Bool {
    return renderableImageExtension(ext:self)
  }
}

public func renderableImageExtension(ext : String) -> Bool {
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
