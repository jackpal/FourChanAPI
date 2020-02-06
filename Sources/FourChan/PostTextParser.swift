import Foundation

public class PostTextParser {
  public enum Element {
    case plain(text: String)
    case bold(text: String)
    case strikethrough(text: String)
    case quote(text: String)
    case deadLink(text: String)
    case anchor(text: String, href: String)
  }
  
  public init(){}

  public func parse(text: String, consumer: (Element) -> Void ) {
    var tagStack: [String] = []
    textCoalescingTokenizer(text: text) {
      switch($0) {
      case .text(let text):
        if let context = tagStack.last {
          switch context {
          case "<b>":
            consumer(.bold(text:text))
          case "<s>":
            consumer(.strikethrough(text: text))
          case #"<span class="quote">"#:
            consumer(.quote(text: text))
          case #"<span class="deadlink">"#:
            consumer(.deadLink(text: text))
          default:
            if context.starts(with: "<a ") {
              var hrefText = ""
              if let hrefRange = context.range(of: #"href="[^"]*""#,
                                               options: .regularExpression) {
                let start = context.index(hrefRange.lowerBound, offsetBy: 6)
                let end = context.index(hrefRange.upperBound, offsetBy: -1)
                hrefText = String(context[start..<end])
              }
              consumer(.anchor(text:text, href:hrefText))
            }
          }
        } else {
          consumer(.plain(text:text))
        }
      case .start(let text):
        tagStack.append(text)
      case .end:
        _ = tagStack.popLast()
      }
    }
  }
  
  private enum Token {
    case text(text:String)
    case start(tag: String)
    case end(tag: String)
  }
  
  private let entityDictionary : [String: Character]  = [
    "&#039;": "'",
    "&#044;": ",",
    "&amp;": "&",
    "&gt;": ">",
    "&lt;": "<",
    "&quot;": "\""
  ]
  
  private func tokenize(text: String, consumer: (Token) -> Void) {
    var chunk = text[...]
    while !chunk.isEmpty {
      if let splitRange = chunk.range(of: #"<|&"#, options: .regularExpression) {
        let prefix = chunk[..<splitRange.lowerBound]
        if !prefix.isEmpty {
          consumer(.text(text:String(prefix)))
        }
        let remainder = chunk[splitRange.lowerBound...]
        let splitChar = remainder.prefix(1)
        if splitChar == "<" {
          if let tagRange = remainder.range(of: #"<[^>]*>"#, options: .regularExpression) {
            let tag = remainder[tagRange]
            if tag.prefix(2) == "</" {
              consumer(.end(tag:String(tag)))
            } else {
              consumer(.start(tag:String(tag)))
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
              consumer(.text(text:entity))
            }
            chunk = remainder[entityRange.upperBound...]
          } else {
            // Error condition, report remainder as plain text
            consumer(.text(text: String(remainder)))
            break
          }
        }
      } else {
        consumer(.text(text:String(chunk)))
        break
      }
    }
  }
  
  // Handles <br>, <wbr>, and combines sequences of text into one text.
  private func textCoalescingTokenizer(text: String, consumer: (Token) -> Void) {
    var textBuffer = ""
    tokenize(text:text){
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

