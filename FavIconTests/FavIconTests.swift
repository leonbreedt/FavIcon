//
// FavIcon
// Copyright (C) 2015 Leon Breedt
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

class FavIconTests : XCTestCase {
    func testDetector() {
        performWebRequest("detect icons") { completion in
            do {
                try FavIconDetector.detect(url: "https://google.co.nz") { icons in
                    for icon in icons {
                        print("detected icon: \(icon)")
                    }
                    completion()
                }
            } catch let error {
                XCTFail("failed to detect icons: \(error)")
            }
        }
    }
}

private extension XCTestCase {
    func performWebRequest(description: String, timeout: NSTimeInterval = 5.0, callback: (() -> Void) -> Void) {
        let expectation = expectationWithDescription(description)
        callback(expectation.fulfill)
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
}
