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
    func testDownloadIcons() {
        guard let icons = performScan(url: "https://apple.com") else {
            XCTFail("expected non-null icons")
            return
        }

        XCTAssertEqual(1, icons.count)
        XCTAssertEqual(IconType.classic, icons[0].type)
    }

    private func performScan(url: String, timeout: TimeInterval = 15.0) -> [Icon]? {
        var actualIcons: [Icon]?

        let scanCompleted = expectation(description: "scan: \(url)")
        FavIcon.scan(URL(string: url)!) { icons in
            actualIcons = icons
            scanCompleted.fulfill()
        }
        wait(for: [scanCompleted], timeout: timeout)

        return actualIcons
    }
}

