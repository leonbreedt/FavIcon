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
        XCTAssertEqual(1, actualIcons.count)
        XCTAssertEqual(URL(string: "https://apple.com/favicon.ico")!, actualIcons[0].url)
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

        XCTAssertEqual(1, actualResults.count)

        switch actualResults[0] {
        case .success(let image):
            XCTAssertEqual(64, image.size.width)
            XCTAssertEqual(64, image.size.height)
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

        var icon = FavIcon.chooseIcon(mixedIcons, width: 50, height: 50)

        XCTAssertNotNil(icon)
        XCTAssertEqual(64, icon!.width)
        XCTAssertEqual(64, icon!.height)

        icon = FavIcon.chooseIcon(mixedIcons, width: 28, height: 28)

        XCTAssertNotNil(icon)
        XCTAssertEqual(32, icon!.width)
        XCTAssertEqual(32, icon!.height)

        icon = FavIcon.chooseIcon(mixedIcons)

        XCTAssertNotNil(icon)
        XCTAssertEqual(144, icon!.width)
        XCTAssertEqual(144, icon!.height)

        icon = FavIcon.chooseIcon(noSizeIcons)

        XCTAssertNotNil(icon)
        XCTAssertEqual(IconType.shortcut.rawValue, icon!.type.rawValue)

        icon = FavIcon.chooseIcon([])

        XCTAssertNil(icon)
    }
}

