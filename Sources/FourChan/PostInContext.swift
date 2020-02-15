#if canImport(CoreGraphics)
import CoreGraphics
#endif

import Foundation

/**
 A boardname, thread, and post.
 
 This object isn't part of the official FourChanAPI, but it's a useful
 construct for processing 4Chan posts, so we include it in our library.
 */
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

public extension PostInContext {
  
  var image : FourChanAPIEndpoint? {
    if let tim = post.tim, let ext = post.ext, ext.isReadableImageType() {
      return FourChanAPIEndpoint.image(board: board, tim: tim, ext: ext)
    } else {
      return nil
    }
  }
  
  var thumbNail: FourChanAPIEndpoint? {
    if let tim = post.tim, let ext = post.ext, ext.isReadableImageType() {
      return FourChanAPIEndpoint.thumbnail(board: board, tim: tim)
    } else {
      return nil
    }
  }
  
  // A rendereable image. Might be the thumbnail if the image isn't a renderable type.
  var renderableImage: FourChanAPIEndpoint? {
    if let ext = post.ext, ext.isReadableImageType() {
      return image
    }
    return thumbNail
  }
  
  /** Returns the post's image URL.
   If the image isn't renderable, return the thumbnail.
   */
  var renderableImageURL: URL? {
    renderableImage?.url()
  }
  
}

#if canImport(CoreGraphics)

public extension PostInContext {

  var imageSize: CGSize? {
    if let w = post.w,
      let h = post.h {
      return CGSize(width: CGFloat(w), height: CGFloat(h))
    }
    return nil
  }
  
  var thumbNailSize: CGSize? {
    if let w = post.tn_w,
      let h = post.tn_w {
      return CGSize(width: CGFloat(w), height: CGFloat(h))
    }
    return nil
  }
  
  /// Return the renderableImageURL image's size.
  var renderableImageSize: CGSize? {
    if let ext = post.ext, ext.isReadableImageType() {
      return imageSize
    }
    return thumbNailSize
  }
}

#endif // canImport(CoreGraphics)
