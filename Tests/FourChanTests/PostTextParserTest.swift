import XCTest
@testable import FourChan
import Combine

/// Tests that actually hit the real FourChan Servers.
final class PostTextParserTest: XCTestCase {

  func testPlain() {
    let result = parse(text: "abc def")
    XCTAssertEqual(result, [.plain(text: "abc def")])
  }

  func testBold() {
    let result = parse(text: "abc<b>def</b>ghi")
    XCTAssertEqual(result, [
      .plain(text: "abc"),
      .bold(text: "def"),
      .plain(text: "ghi")
    ])
  }

  func testStrikethrough() {
    let result = parse(text: "abc<s>def</s>ghi")
    XCTAssertEqual(result, [
      .plain(text: "abc"),
      .strikethrough(text: "def"),
      .plain(text: "ghi")
    ])
  }

  func testQuote() {
    let result = parse(text: #"abc<span class="quote">def</span>ghi"#)
    XCTAssertEqual(result, [
      .plain(text: "abc"),
      .quote(text: "def"),
      .plain(text: "ghi")
    ])
  }

  func testDeadlink() {
    let result = parse(text: #"abc<span class="deadlink">def</span>ghi"#)
    XCTAssertEqual(result, [
      .plain(text: "abc"),
      .deadLink(text: "def"),
      .plain(text: "ghi")
    ])
  }

  func testCode() {
    let result = parse(text: #"abc<pre class="prettyprint">def<br>ghi</pre>jkl"#)
    XCTAssertEqual(result, [
      .plain(text: "abc"),
      .code(text: "def\nghi"),
      .plain(text: "jkl")
    ])
  }

  func testALink() {
    let result = parse(text: ##"abc<a href="#foo">def</a>ghi"##)
    XCTAssertEqual(result, [
      .plain(text: "abc"),
      .anchor(text: "def", href: "#foo"),
      .plain(text: "ghi")
    ])
  }

  func testRawLink() {
    let result = parse(text: ##"abc example.com/a/b.gif http://example.com/e<wbr>/f.gif ghi https://example.com/b jkl"##)
    let link1 = "example.com/a/b.gif"
    let link2 = "http://example.com/e\u{200b}/f.gif"
    let href2 = "http://example.com/e/f.gif"
    let link3 = "https://example.com/b"
    XCTAssertEqual(result, [
      .plain(text: "abc "),
      .anchor(text: link1, href: link1),
      .plain(text: " "),
      .anchor(text: link2, href: href2),
      .plain(text: " ghi "),
      .anchor(text: link3, href: link3),
      .plain(text: " jkl"),
    ])
  }

  func testRawMagnetLink() {
    let result = parse(text: ##"abc magnet:?xt=urn:udp:xd def"##)
    let link = "magnet:?xt=urn:udp:xd"
    XCTAssertEqual(result, [
      .plain(text: "abc "),
      .anchor(text: link, href: link),
      .plain(text: " def"),
    ])
  }
  
  func testEntity() {
    let result = parse(text: #"&#039;&#044;&amp;&gt;&lt;&quot;"#)
    XCTAssertEqual(result, [
      .plain(text: "',&><\""),
    ])
  }

  func testBR() {
    let result = parse(text: #"abc<br><br>def<wbr>ghi"#)
    XCTAssertEqual(result, [
      .plain(text: "abc\n\ndef\u{200b}ghi")
    ])
  }

  // MARK: Private methods
  func parse(text: String) -> [PostTextParser.Element] {
    var accumulator: [PostTextParser.Element] = []
    PostTextParser().parse(text: text) {
      accumulator.append($0)
    }
    return accumulator
  }
}
