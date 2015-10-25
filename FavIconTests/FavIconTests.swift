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
    func testDetection() {
        performWebRequest("detect icons") { completion in
            do {
                try FavIcons.detect(url: "https://soundcloud.com") { icons in
                    completion()
                    
                    for icon in icons {
                        print("detected icon: \(icon)")
                    }
                }
            } catch let error {
                XCTFail("failed to detect icons: \(error)")
                completion()
            }
        }
    }
    
    func testDownloading() {
        self.performWebRequest("download icons") { completion in
            do {
                try FavIcons.download(url: "https://soundcloud.com") { results in
                    completion()
                    
                    for result in results {
                        print("downloaded icon: \(result)")
                    }
                }
            } catch let error {
                XCTFail("failed to download icons: \(error)")
                completion()
            }
        }
    }
    
    func testHTMLHeadIconExtraction() {
        let html = stringForContentsOfFile(pathForTestBundleResource("SampleHTMLFile.html")) ?? ""
        let document = HTMLDocument(string: html)
        
        let icons = FavIcons.extractHTMLHeadIcons(document, baseURL: NSURL(string: "https://localhost")!)
        
        XCTAssertEqual(5, icons.count)
        
        XCTAssertEqual("https://localhost/shortcut.ico", icons[0].url.absoluteString)
        XCTAssertEqual(DetectedIconType.Shortcut.rawValue, icons[0].type.rawValue)
        XCTAssertEqual("https://localhost/content/images/favicon-96x96.png", icons[1].url.absoluteString)
        XCTAssertEqual(DetectedIconType.GoogleTV.rawValue, icons[1].type.rawValue)
        XCTAssertEqual("https://localhost/content/images/favicon-16x16.png", icons[2].url.absoluteString)
        XCTAssertEqual(DetectedIconType.FavIcon.rawValue, icons[2].type.rawValue)
        XCTAssertEqual("https://localhost/content/images/favicon-32x32.png", icons[3].url.absoluteString)
        XCTAssertEqual(DetectedIconType.AppleOSXSafari.rawValue, icons[3].type.rawValue)
        XCTAssertEqual("https://localhost/content/icons/favicon-192x192.png", icons[4].url.absoluteString)
        XCTAssertEqual(DetectedIconType.GoogleAndroidChrome.rawValue, icons[4].type.rawValue)
    }
 
    private func pathForTestBundleResource(fileName: String) -> String {
        let testBundle = NSBundle(forClass: FavIconTests.self)
        return testBundle.pathForResource(fileName, ofType: "")!
    }
    
    private func stringForContentsOfFile(filePath: String, encoding: UInt = NSUTF8StringEncoding) -> String? {
        return try? NSString(contentsOfFile: filePath, encoding: encoding) as String
    }
}

private extension XCTestCase {
    func performWebRequest(description: String, timeout: NSTimeInterval = 5.0, callback: (() -> Void) -> Void) {
        let expectation = expectationWithDescription(description)
        callback(expectation.fulfill)
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
}
