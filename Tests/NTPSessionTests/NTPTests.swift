import XCTest
@testable import NTPSession

final class NTPTests: XCTestCase {
    func testRegister() {
        XCTAssertEqual(NTP.registered, true)
    }

    func testCanInitSuccess() throws {
        guard let url = URL(string: "ntp://test.com") else {
            XCTFail("url should not be bad")
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request)
        XCTAssertTrue(NTP.canInit(with: task))
        XCTAssertTrue(NTP.canInit(with: request))
    }

    func testCanInitFail() {
        guard let url = URL(string: "http://test.com") else {
            XCTFail("url should not be bad")
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request)
        XCTAssertFalse(NTP.canInit(with: task))
        XCTAssertFalse(NTP.canInit(with: request))
    }

    func testCanonicalRequest() {
        guard let url = URL(string: "nTp://test.com") else {
            XCTFail("url should not be bad")
            return
        }
        let request = URLRequest(url: url)
        XCTAssertEqual(request, NTP.canonicalRequest(for: request))
    }

    func testInitRequest() {
        guard let url = URL(string: "Ntp://test.com") else {
            XCTFail("url should not be bad")
            return
        }
        let request = URLRequest(url: url)
        let ntp = NTP(request: request)
        XCTAssertEqual(ntp.request, request)
    }

    func testInitTask() throws {
        guard let url = URL(string: "Ntp://test.com") else {
            XCTFail("url should not be bad")
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url))
        let ntp = NTP(task: task, cachedResponse: nil, client: nil)
        XCTAssertEqual(ntp.request, task.currentRequest)
    }

    func test() throws {
        let expectation = XCTestExpectation()
        NTP.register
        let request = URL(string: "ntp://time.apple.com")!
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("error should be nil not \"\(error!)\"" +
                            " and data should not be nil")
                return
            }

            let date = data.withUnsafeBytes { $0.load(as: Date.self) }
            print("Current Date = \(Date())")
            print("New Date     = \(date)")
            XCTAssertEqual(Date().timeIntervalSince1970,
                           date.timeIntervalSince1970,
                           accuracy: 30.0)
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 30.0)
    }

    static var allTests = [
        ("testRegister", testRegister),
        ("testCanInitSuccess", testCanInitSuccess),
        ("testCanInitFail", testCanInitFail),
        ("testInitRequest", testInitRequest),
        ("testInitTask", testInitTask),
    ]
}
