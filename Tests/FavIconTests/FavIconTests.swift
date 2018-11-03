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

class FavIconTests: XCTestCase {
    func testScan() {
        let url = "https://apple.com"
        var actualIcons: [Icon]!

        let completed = expectation(description: "scan: \(url)")
        do {
            try FavIcon.scan(url) { icons in
                actualIcons = icons
                completed.fulfill()
            }
        } catch let error {
            XCTFail("failed to scan for icons: \(error)")
        }
        wait(for: [completed], timeout: 15)

        XCTAssertNotNil(actualIcons)
        XCTAssertEqual(2, actualIcons.count)
        XCTAssertEqual(URL(string: "https://apple.com/favicon.ico")!, actualIcons[0].url)
    }
    
    func testIssue24_LowResIcons() {
        let url = "https://www.facebook.com"
        var actualResult: IconDownloadResult!
        
        let completed = expectation(description: "download: \(url)")
        do {
            try FavIcon.downloadPreferred(url) { result in
                actualResult = result
                completed.fulfill()
            }
        } catch let error {
            XCTFail("failed to download icons: \(error)")
        }
        wait(for: [completed], timeout: 15)
        
        XCTAssertNotNil(actualResult)
        
        switch actualResult! {
        case .success(let image):
            XCTAssertEqual(325.0, image.size.width)
            XCTAssertEqual(325.0, image.size.height)
            break
        case .failure(let error):
            XCTFail("unexpected error returned for download: \(error)")
            break
        }
    }

    func testDownloading() {
        let url = "https://apple.com"
        var actualResults: [IconDownloadResult]!

        let completed = expectation(description: "download: \(url)")
        do {
            try FavIcon.downloadAll(url) { results in
                actualResults = results
                completed.fulfill()
            }
        } catch let error {
            XCTFail("failed to download icons: \(error)")
        }
        wait(for: [completed], timeout: 15)

        XCTAssertEqual(2, actualResults.count)

        switch actualResults[0] {
        case .success(let image):
            XCTAssertEqual(1200, image.size.width)
            XCTAssertEqual(630, image.size.height)
            break
        case .failure(let error):
            XCTFail("unexpected error returned for download: \(error)")
            break
        }
    }

    func testChooseIcon() {
        let mixedIcons = [
            Icon(url: URL(string: "https://google.com/favicon.ico")!, type: .shortcut, width: 32, height: 32),
            Icon(url: URL(string: "https://google.com/favicon.ico")!, type: .classic, width: 64, height: 64),
            Icon(url: URL(string: "https://google.com/favicon.ico")!, type: .appleIOSWebClip, width: 64, height: 64),
            Icon(url: URL(string: "https://google.com/favicon.ico")!, type: .appleOSXSafariTab, width: 144, height: 144),
            Icon(url: URL(string: "https://google.com/favicon.ico")!, type: .classic)
        ]
        let noSizeIcons = [
            Icon(url: URL(string: "https://google.com/favicon.ico")!, type: .classic),
            Icon(url: URL(string: "https://google.com/favicon.ico")!, type: .shortcut)
        ]

        var sortedIcons = FavIcon.sortIcons(mixedIcons, preferredWidth: 50, preferredHeight: 50)
        var icon = sortedIcons[0]

        XCTAssertNotNil(icon)
        XCTAssertEqual(64, icon.width)
        XCTAssertEqual(64, icon.height)

        sortedIcons = FavIcon.sortIcons(mixedIcons, preferredWidth: 28, preferredHeight: 28)
        icon = sortedIcons[0]

        XCTAssertNotNil(icon)
        XCTAssertEqual(32, icon.width)
        XCTAssertEqual(32, icon.height)

        sortedIcons = FavIcon.sortIcons(mixedIcons)
        icon = sortedIcons[0]

        XCTAssertNotNil(icon)
        XCTAssertEqual(144, icon.width)
        XCTAssertEqual(144, icon.height)

        sortedIcons = FavIcon.sortIcons(noSizeIcons)
        icon = sortedIcons[0]

        XCTAssertNotNil(icon)
        XCTAssertEqual(IconType.shortcut.rawValue, icon.type.rawValue)

        sortedIcons = FavIcon.sortIcons([])

        XCTAssertEqual(0, sortedIcons.count)
    }
}

