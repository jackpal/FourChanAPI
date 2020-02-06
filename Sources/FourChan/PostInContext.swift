#if canImport(CoreGraphics)
import CoreGraphics
#endif
import Foundation

// A boardname, thread, and post.
// This object isn't part of the official FourChanAPI, but it's a useful
// construct for processing 4Chan posts, so we include it in our library.
public struct PostInContext {
  public let board: BoardName
  public let thread: Int
  public let post: Post
  
  public init(board: BoardName, thread: Int, post: Post) {
    self.board = board
    self.thread = thread
    self.post = post
  }
}

#if canImport(CoreGraphics)
extension PostInContext {
  
  public var imageURL: URL? {
    var url: URL? = nil
    if let tim = post.tim, let ext = post.ext, ext.isReadableImageType() {
      url = FourChanAPIService.Endpoint
        .image(board: board, tim: tim, ext: ext).url()
    } else if let tim = post.tim {
      url = FourChanAPIService.Endpoint
        .thumbnail(board: board, tim: tim).url()
    }
    
    return url
  }
  
  public var imageSize: CGSize? {
    var w = 0
    var h = 0
    if post.ext?.isReadableImageType() ?? false {
      w = post.w ?? 0
      h = post.h ?? 0
    } else {
      w = post.tn_w ?? 0
      h = post.tn_h ?? 0
    }
    
    if w == 0 || h == 0 {
      return nil
    }
    
    return CGSize(width: CGFloat(w), height: CGFloat(h))
  }
}

#endif
