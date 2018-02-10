//
// FavIcon
// Copyright © 2018 Leon Breedt
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
@testable import FavIcon

import Foundation

class DownloadTests: XCTestCase {
    func testDownloadText() {
        let result = performDownload(url: "https://apple.com")

        XCTAssertNotNil(result)

        if case .text(let value, let mimeType, _) = result! {
            XCTAssertEqual("text/html", mimeType)
            XCTAssertTrue(value.count > 0)
        } else {
            XCTFail("expected text response")
        }
    }

    func testDownloadTextAndImage() {
        let results = performDownloads(urls: ["https://apple.com", "https://apple.com/favicon.ico"])

        XCTAssertNotNil(results)

        if case .text(let value, let mimeType, _) = results![0] {
            XCTAssertEqual("text/html", mimeType)
            XCTAssertTrue(value.count > 0)
        } else {
            XCTFail("expected text response for first result")
        }

        if case .binary(let data, let mimeType, _) = results![1] {
            XCTAssertEqual("image/x-icon", mimeType)
            XCTAssertTrue(data.count > 0)
        } else {
            XCTFail("expected binary response for second result")
        }
}

    func testDownloadImage() {
        let result = performDownload(url: "https://google.com/favicon.ico")

        XCTAssertNotNil(result)

        if case .binary(let data, let mimeType, _) = result! {
            XCTAssertEqual("image/x-icon", mimeType)
            XCTAssertTrue(data.count > 0)
        } else {
            XCTFail("expected binary response")
        }
    }

    private func performDownloads(urls: [String], timeout: TimeInterval = 15.0) -> [DownloadResult]? {
        var actualResults: [DownloadResult]?

        let downloadsCompleted = expectation(description: "download: \(urls)")
        downloadURLs(urls.map { URL(string: $0)!}) { results in
            actualResults = results
            downloadsCompleted.fulfill()
        }
        wait(for: [downloadsCompleted], timeout: timeout)

        return actualResults
    }

    private func performDownload(url: String, timeout: TimeInterval = 15.0) -> DownloadResult? {
        var actualResult: DownloadResult?

        let downloadCompleted = expectation(description: "download: \(url)")
        downloadURL(URL(string: url)!) { result in
            actualResult = result
            downloadCompleted.fulfill()
        }
        wait(for: [downloadCompleted], timeout: timeout)

        return actualResult
    }
}
