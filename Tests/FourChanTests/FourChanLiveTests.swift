import XCTest
@testable import FourChan
import Combine

/// Tests that actually hit the real FourChan Servers.
final class FourChanLiveTests: XCTestCase {
  
  func testFourChanLoader() {
    let publisher = FourChanLoader.fourChanPublisher()
    let validTest = evalValidResponseTest(publisher: publisher)
    wait(for: validTest.expectations, timeout: 10)
    validTest.cancellable?.cancel()
  }
  
  func testCatalogLoader() {
    let publisher = CatalogLoader.publisher(board: "a")
    let validTest = evalValidResponseTest(publisher: publisher)
    wait(for: validTest.expectations, timeout: 10)
    validTest.cancellable?.cancel()
  }
  
  func testChanThreadLoader() {
    let publisher = CatalogLoader.publisher(board: "a")
      .flatMap(maxPublishers: .max(1)) { (catalog:Catalog) -> AnyPublisher<ChanThread,Error> in
        let no = catalog.first?.threads.first?.no ?? 0
        return ChanThreadLoader.publisher(board: "a", no:no)
    }
    let validTest = evalValidResponseTest(publisher: publisher)
    wait(for: validTest.expectations, timeout: 10)
    validTest.cancellable?.cancel()
  }
  
  // MARK: Measuring time to fetch images.
  
  func testImageDatas() {
    let publisher = FourChanService.shared.posts(board:"a")
      .imageDatas()
      .collect(100)
    let validTest = evalValidResponseTest(publisher: publisher)
    wait(for: validTest.expectations, timeout: 100)
    validTest.cancellable?.cancel()
  }

  // MARK: Private methods
  
  // Adapted from https://medium.com/better-programming/swift-unit-test-a-datataskpublisher-with-urlprotocol-2fbda186758e
  func evalValidResponseTest<T:Publisher>(publisher: T?) -> (expectations:[XCTestExpectation], cancellable: AnyCancellable?) {
    XCTAssertNotNil(publisher)
    
    //let expectationFinished = expectation(description: "finished")
    let expectationReceive = expectation(description: "receiveValue")
    //let expectationFailure = expectation(description: "failure")
    //expectationFailure.isInverted = true
    
    let cancellable = publisher?.sink (receiveCompletion: { (completion) in
      switch completion {
      case .failure(let error):
        print("--TEST ERROR--")
        print(error.localizedDescription)
        print("------")
        // expectationFailure.fulfill()
        XCTFail(error.localizedDescription)
      case .finished:
        // expectationFinished.fulfill()
        break
      }
    }, receiveValue: { response in
      XCTAssertNotNil(response)
      expectationReceive.fulfill()
    })
    return (expectations: [expectationReceive],
            cancellable: cancellable)
  }
  
  
  static var allTests = [
    ("testFourChanLoader", testFourChanLoader),
    ("testCatalogLoader", testCatalogLoader),
    ("testChanThreadLoader", testChanThreadLoader),
    ("testImageDatas", testImageDatas),
  ]
}
