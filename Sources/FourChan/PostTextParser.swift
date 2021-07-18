import Foundation

public struct PostTextParser {
  public enum Element: Equatable {
    case plain(text: String)
    case bold(text: String)
    case strikethrough(text: String)
    case quote(text: String)
    case deadLink(text: String)
    case anchor(text: String, href: String)
  }

  /// Matches in-code URLs. See https://gist.github.com/gruber/8891611
  let urlRegEx = try! NSRegularExpression(
    pattern: #"(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b/?(?!@)))"#,
    options: [])

  public init() {}

  public func parse(text: String, consumer: (Element) -> Void) {
    var tagStack: [String] = []
    textCoalescingTokenizer(text: text) {
      switch $0 {
      case .text(let text):
        if let context = tagStack.last {
          switch context {
          case "<b>":
            consumer(.bold(text: text))
          case "<s>":
            consumer(.strikethrough(text: text))
          case #"<span class="quote">"#:
            consumer(.quote(text: text))
          case #"<span class="deadlink">"#:
            consumer(.deadLink(text: text))
          default:
            if context.starts(with: "<a ") {
              var hrefText = ""
              if let hrefRange = context.range(
                of: #"href="[^"]*""#,
                options: .regularExpression)
              {
                let start = context.index(hrefRange.lowerBound, offsetBy: 6)
                let end = context.index(hrefRange.upperBound, offsetBy: -1)
                hrefText = String(context[start..<end])
              }
              consumer(.anchor(text: text, href: hrefText))
            }
          }
        } else {
          let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
          var lastConsumedIndex = nsrange.lowerBound
          let matches = urlRegEx.matches(in: text, options: [], range: nsrange)
          for match in matches {
            let range = match.range
            if lastConsumedIndex < range.lowerBound {
              let prefix = NSRange(location: lastConsumedIndex, length: range.lowerBound - lastConsumedIndex)
              consumer(.plain(text: String(text[Range(prefix, in: text)!])))
            }
            let url = String(text[Range(range, in: text)!])
            consumer(.anchor(text:url, href: url))
            lastConsumedIndex = range.upperBound
          }
          if lastConsumedIndex < nsrange.upperBound {
            let prefix = NSRange(location: lastConsumedIndex, length: nsrange.upperBound - lastConsumedIndex)
            consumer(.plain(text: String(text[Range(prefix, in: text)!])))
          }
        }
      case .start(let text):
        tagStack.append(text)
      case .end:
        _ = tagStack.popLast()
      }
    }
  }

  private enum Token {
    case text(text: String)
    case start(tag: String)
    case end(tag: String)
  }

  private let entityDictionary: [String: Character] = [
    "&#039;": "'",
    "&#044;": ",",
    "&amp;": "&",
    "&gt;": ">",
    "&lt;": "<",
    "&quot;": "\"",
  ]

  private func tokenize(text: String, consumer: (Token) -> Void) {
    var chunk = text[...]
    while !chunk.isEmpty {
      if let splitRange = chunk.range(of: #"<|&"#, options: .regularExpression) {
        let prefix = chunk[..<splitRange.lowerBound]
        if !prefix.isEmpty {
          consumer(.text(text: String(prefix)))
        }
        let remainder = chunk[splitRange.lowerBound...]
        let splitChar = remainder.prefix(1)
        if splitChar == "<" {
          if let tagRange = remainder.range(of: #"<[^>]*>"#, options: .regularExpression) {
            let tag = remainder[tagRange]
            if tag.prefix(2) == "</" {
              consumer(.end(tag: String(tag)))
            } else {
              consumer(.start(tag: String(tag)))
            }
            chunk = remainder[tagRange.upperBound...]
          } else {
            // Error condition, report remainder as plain text
            consumer(.text(text: String(remainder)))
            break
          }
        } else {
          if let entityRange = remainder.range(of: #"&[^;]*;"#, options: .regularExpression) {
            let entity = String(remainder[entityRange])
            if let decodedEntity = entityDictionary[entity] {
              consumer(.text(text: String(decodedEntity)))
            } else {
              // Unknown entity
              consumer(.text(text: entity))
            }
            chunk = remainder[entityRange.upperBound...]
          } else {
            // Error condition, report remainder as plain text
            consumer(.text(text: String(remainder)))
            break
          }
        }
      } else {
        consumer(.text(text: String(chunk)))
        break
      }
    }
  }

  // Handles <br>, <wbr>, and combines sequences of text into one text.
  private func textCoalescingTokenizer(text: String, consumer: (Token) -> Void) {
    var textBuffer = ""
    tokenize(text: text) {
      switch $0 {
      case .text(let text):
        textBuffer += text
      case .start(let text):
        switch text {
        case "<br>":
          textBuffer += "\n"
        case "<wbr>":
          textBuffer += "\u{200b}"
        default:
          if !textBuffer.isEmpty {
            consumer(.text(text: textBuffer))
            textBuffer = ""
          }
          consumer(.start(tag: text))
        }
      case .end(let text):
        if !textBuffer.isEmpty {
          consumer(.text(text: textBuffer))
          textBuffer = ""
        }
        consumer(.end(tag: text))
      }
    }
    if !textBuffer.isEmpty {
      consumer(.text(text: textBuffer))
    }
  }
}
