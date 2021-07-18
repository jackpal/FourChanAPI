import Foundation

// See https://github.com/4chan/4chan-API

public typealias PostNumber = Int
public typealias BoardName = String
public typealias PageNumber = Int
public typealias ImageNumber = Int

public typealias Archive = [PostNumber]

public typealias Catalog = [Page]

public struct Board: Codable, Hashable {
  public let board: BoardName
  public let title: String

  /// Worksafe board
  public let ws_board: Int

  public let per_page: Int
  public let pages: Int
  public let max_filesize: Int
  public let max_webm_filesize: Int
  public let max_comment_chars: Int
  public let max_webm_duration: Int
  public let bump_limit: Int
  public let image_limit: Int

  public struct Cooldowns: Codable, Hashable {
    public let threads: Int
    public let replies: Int
    public let images: Int
  }

  public let cooldowns: Cooldowns
  public let meta_description: String
  /// Are spoilers enabled
  public let spoilers: Int?
  /// How many custom spoilers does the board have
  public let custom_spoilers: Int?
  public let is_archived: Int?
  /// Key: Flag Code, Value: Flag Name
  public let board_flags: [String:String]?
  /// Are flags showing the poster's country enabled on the board
  public let country_flags: Int?
  /// Are poster ID tags enabled on the board
  public let user_ids: Int?
  /// Can users submit drawings via browser the Oekaki app
  public let oekaki: Int?
  /// Can users submit sjis drawings using the [sjis] tags
  public let sjis_tags: Int?
  /// Board supports code syntax highlighting using the [code] tags
  public let code_tags: Int?
  /// Board supports [math] TeX and [eqn] tags
  public let math_tags: Int?
  /// Is image posting disabled for the board
  public let text_only: Int?
  /// Is the name field disabled on the board
  public let forced_anon: Int?
  /// Are webms with audio allowed?
  public let webm_audio: Int?
  /// Do OPs require a subject
  public let require_subject: Int?
  /// What is the minimum image width (in pixels)
  public let min_image_width: Int?
  /// What is the minimum image height (in pixels)
  public let min_image_height: Int?
}

extension Board: Identifiable {
  public var id: String {
    board
  }
}

public struct Boards: Codable {
  public let boards: [Board]
}

public typealias Posts = [Post]

public struct Page: Codable {
  public let page: Int
  public let threads: Posts
}

extension Page: Identifiable {
  public var id: Int {
    page
  }
}

public typealias Pages = [Page]

/// A message from a user.
public struct Post: Codable, Hashable {
  /// Post number.
  public let no: PostNumber

  /// Reply to. (Presumably short for "response to")
  public let resto: PostNumber?

  /// Stickied Thread
  public let sticky: Int?

  /// Closed thread
  public let closed: Int?

  /// Archived thread.
  public let archived: Int?

  /// Time when archived. Unix timestamp.
  public let archived_on: Int?

  /// Date and time. MM/DD/YY(Day)HH:MM (:SS on some boards), EST/EDT timezone
  public let now: String?

  /// User name.
  public let name: String?

  /// Tripcode.
  public let trip: String?

  // The poster's ID. Any 8 characters.
  public let pid: String?

  /// Capcode
  public let capcode: String?

  /// Country code. 2 characters ISO 3166-1 alpha-2
  public let country: String?

  /// Country name.
  public let country_name: String?

  /// Poster's board flag code
  public let board_flag: String?

  /// Poster's board flag name
  public let flag_name: String?

  /// Subject
  public let sub: String?

  /// Comment. Includes escaped HTML.
  public let com: String?

  /// Renamed filename (for fetching image).
  /// Based on unix timestamp plus milliseconds.
  public let tim: ImageNumber?

  /// Original filename.
  public let filename: String?

  /// File extension. .jpg, .png, .gif, .pdf, .swf, .webm
  public let ext: String?

  /// File-size.
  public let fsize: Int?

  /// File MD5.
  public let md5: String?

  /// Image width.
  public let w: Int?

  /// Image height.
  public let h: Int?

  /// Thumbnail width.
  public let tn_w: Int?

  /// Thumbnail height.
  public let tn_h: Int?

  /// File deleted?
  public let filedeleted: Int?

  /// Spoiler image?
  public let spoiler: Int?

  /// Custom spoiler 1-99
  public let custom_spoiler: Int?

  /// Omitted posts.
  public let omitted_posts: Int?

  /// Omitted images.
  public let omitted_images: Int?

  /// Unix timestamp.
  public let time: Int?

  /// Thread URL slug.
  public let semantic_url: String?

  /// Number of unique IPs in thread.
  public let unique_ips: Int?

  public let replies: Int?
  public let images: Int?

  /// Bump limit met?
  public let bumplimit: Int?

  /// Image limit met?
  public let imagelimit: Int?

  // Only displays on /q/, which is not an active board.
  // let capcode_replies
  public let lastReplies: [ChanThread]?

  /// Time when last modified Unix timestamp.
  public let last_modified: Int?

  /// Thread tag.
  /// 
  /// Only displays on /f/
  public let tag: String?

  /// Year 4chan pass bought.
  public let since4pass: Int?

  /// Mobile optimized image exists for post
  public let m_img: Int?

}

extension Post: Identifiable {
  public var id: Int { return no }
}

extension Post {
  enum CodingKeys: String, CodingKey {
      case pid = "id"
      case no, resto, sticky, closed, archived, archived_on, now,
           name, trip, capcode, country, country_name, board_flag, flag_name, sub, com,
           tim, filename, ext, fsize, md5, w, h, tn_w, tn_h, filedeleted,
           spoiler, custom_spoiler, omitted_posts, omitted_images, time, semantic_url, unique_ips,
           replies, images, bumplimit, imagelimit, lastReplies, last_modified, tag, since4pass, m_img
  }
}

/// A FourChan Thread.
///
/// Naming this "Thread" causes SwiftUI previews to fail to compile.
/// Error: 'Thread' is ambiguous for type lookup in this context
public struct ChanThread: Codable, Hashable {
  public let posts: Posts
}

extension ChanThread: Identifiable {
  public var id: Int {
    if posts.count > 0 {
      return posts[0].no
    }
    return 0
  }
}

public typealias ChanThreads = [ChanThread]

public struct Threads: Codable, Hashable {
  let threads: ChanThreads
}

extension String {
  /**
   Returns the un-escaped version of  an HTML-encoded String.
   
   Just does the conversions actually seen on 4chan content.
   */
  public var clean: String {
    self
      .replacingOccurrences(of: "&#039;", with: "'")
      .replacingOccurrences(of: "&#044;", with: ",")
      .replacingOccurrences(of: "&amp;", with: "&")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "<br>", with: "\n")
      .replacingOccurrences(of: "<wbr>", with: "\u{200b}")
  }
}
