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

class DetectionTests: XCTestCase {
    func testManifestJSONDetection() {
        let json = stringForContentsOfFile(filePath: pathForTestBundleResource(fileName: "Manifest.json")) ?? ""
        let icons = detectWebAppManifestIcons(json, baseURL: URL(string: "https://localhost")!.absoluteURL)

        XCTAssertEqual(6, icons.count)

        XCTAssertEqual("https://localhost/launcher-icon-0-75x.png", icons[0].url.absoluteString)
        XCTAssertEqual(IconType.webAppManifest.rawValue, icons[0].type.rawValue)
        XCTAssertEqual(36, icons[0].width!)
        XCTAssertEqual(36, icons[0].height!)

        XCTAssertEqual("https://localhost/launcher-icon-1x.png", icons[1].url.absoluteString)
        XCTAssertEqual(IconType.webAppManifest.rawValue, icons[1].type.rawValue)
        XCTAssertEqual(48, icons[1].width!)
        XCTAssertEqual(48, icons[1].height!)

        XCTAssertEqual("https://localhost/launcher-icon-1-5x.png", icons[2].url.absoluteString)
        XCTAssertEqual(IconType.webAppManifest.rawValue, icons[2].type.rawValue)
        XCTAssertEqual(72, icons[2].width!)
        XCTAssertEqual(72, icons[2].height!)

        XCTAssertEqual("https://localhost/launcher-icon-2x.png", icons[3].url.absoluteString)
        XCTAssertEqual(IconType.webAppManifest.rawValue, icons[3].type.rawValue)
        XCTAssertEqual(96, icons[3].width!)
        XCTAssertEqual(96, icons[3].height!)

        XCTAssertEqual("https://localhost/launcher-icon-3x.png", icons[4].url.absoluteString)
        XCTAssertEqual(IconType.webAppManifest.rawValue, icons[4].type.rawValue)
        XCTAssertEqual(144, icons[4].width!)
        XCTAssertEqual(144, icons[4].height!)

        XCTAssertEqual("https://localhost/launcher-icon-4x.png", icons[5].url.absoluteString)
        XCTAssertEqual(IconType.webAppManifest.rawValue, icons[5].type.rawValue)
        XCTAssertEqual(192, icons[5].width!)
        XCTAssertEqual(192, icons[5].height!)
    }

    func testBrowserConfigXMLIconDetection() {
        let xml = stringForContentsOfFile(filePath: pathForTestBundleResource(fileName: "BrowserConfig.xml")) ?? ""
        let document = XMLDocument(string: xml)
        let icons = detectBrowserConfigXMLIcons(document, baseURL: URL(string: "https://localhost")!)

        XCTAssertEqual(5, icons.count)

        XCTAssertEqual("https://localhost/small.png", icons[0].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[0].type.rawValue)
        XCTAssertEqual(70, icons[0].width!)
        XCTAssertEqual(70, icons[0].height!)

        XCTAssertEqual("https://localhost/medium.png", icons[1].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[1].type.rawValue)
        XCTAssertEqual(150, icons[1].width!)
        XCTAssertEqual(150, icons[1].height!)

        XCTAssertEqual("https://localhost/wide.png", icons[2].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[2].type.rawValue)
        XCTAssertEqual(310, icons[2].width!)
        XCTAssertEqual(150, icons[2].height!)

        XCTAssertEqual("https://localhost/large.png", icons[3].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[3].type.rawValue)
        XCTAssertEqual(310, icons[3].width!)
        XCTAssertEqual(310, icons[3].height!)

        XCTAssertEqual("https://localhost/tile.png", icons[4].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[4].type.rawValue)
        XCTAssertEqual(144, icons[4].width!)
        XCTAssertEqual(144, icons[4].height!)
    }

    func testHTMLHeadIconExtraction() {
        let html = stringForContentsOfFile(filePath: pathForTestBundleResource(fileName: "HTML.html")) ?? ""
        let document = HTMLDocument(string: html)
        let icons = detectHTMLHeadIcons(document, baseURL: URL(string: "https://localhost")!)

        XCTAssertEqual(26, icons.count)

        XCTAssertEqual("https://localhost/shortcut.ico", icons[0].url.absoluteString)
        XCTAssertEqual(IconType.shortcut.rawValue, icons[0].type.rawValue)
        XCTAssertNil(icons[0].width)
        XCTAssertNil(icons[0].height)

        XCTAssertEqual("https://localhost/content/images/favicon-96x96.png", icons[1].url.absoluteString)
        XCTAssertEqual(IconType.googleTV.rawValue, icons[1].type.rawValue)
        XCTAssertEqual(96, icons[1].width!)
        XCTAssertEqual(96, icons[1].height!)

        XCTAssertEqual("https://localhost/content/images/favicon-16x16.png", icons[2].url.absoluteString)
        XCTAssertEqual(IconType.classic.rawValue, icons[2].type.rawValue)
        XCTAssertEqual(16, icons[2].width!)
        XCTAssertEqual(16, icons[2].height!)

        XCTAssertEqual("https://localhost/content/images/favicon-32x32.png", icons[3].url.absoluteString)
        XCTAssertEqual(IconType.appleOSXSafariTab.rawValue, icons[3].type.rawValue)
        XCTAssertEqual(32, icons[3].width!)
        XCTAssertEqual(32, icons[3].height!)

        XCTAssertEqual("https://localhost/content/icons/favicon-192x192.png", icons[4].url.absoluteString)
        XCTAssertEqual(IconType.googleAndroidChrome.rawValue, icons[4].type.rawValue)
        XCTAssertEqual(192, icons[4].width!)
        XCTAssertEqual(192, icons[4].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-57x57.png", icons[5].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[5].type.rawValue)
        XCTAssertEqual(57, icons[5].width!)
        XCTAssertEqual(57, icons[5].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-114x114.png", icons[6].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[6].type.rawValue)
        XCTAssertEqual(114, icons[6].width!)
        XCTAssertEqual(114, icons[6].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-72x72.png", icons[7].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[7].type.rawValue)
        XCTAssertEqual(72, icons[7].width!)
        XCTAssertEqual(72, icons[7].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-144x144.png", icons[8].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[8].type.rawValue)
        XCTAssertEqual(144, icons[8].width!)
        XCTAssertEqual(144, icons[8].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-60x60.png", icons[9].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[9].type.rawValue)
        XCTAssertEqual(60, icons[9].width!)
        XCTAssertEqual(60, icons[9].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-120x120.png", icons[10].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[10].type.rawValue)
        XCTAssertEqual(120, icons[10].width!)
        XCTAssertEqual(120, icons[10].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-76x76.png", icons[11].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[11].type.rawValue)
        XCTAssertEqual(76, icons[11].width!)
        XCTAssertEqual(76, icons[11].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-152x152.png", icons[12].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[12].type.rawValue)
        XCTAssertEqual(152, icons[12].width!)
        XCTAssertEqual(152, icons[12].height!)

        XCTAssertEqual("https://localhost/content/images/apple-touch-icon-180x180.png", icons[13].url.absoluteString)
        XCTAssertEqual(IconType.appleIOSWebClip.rawValue, icons[13].type.rawValue)
        XCTAssertEqual(180, icons[13].width!)
        XCTAssertEqual(180, icons[13].height!)

        XCTAssertTrue(icons[14].url.absoluteString.starts(with: "data:"))
        XCTAssertEqual(IconType.shortcut.rawValue, icons[14].type.rawValue)
        XCTAssertNil(icons[14].width)
        XCTAssertNil(icons[14].height)
        
        XCTAssertEqual("https://s.ytimg.com/yts/img/favicon-vfl8qSV2F.ico", icons[15].url.absoluteString)
        XCTAssertEqual(IconType.shortcut.rawValue, icons[15].type.rawValue)
        XCTAssertNil(icons[15].width)
        XCTAssertNil(icons[15].height)
        
        XCTAssertEqual("https://s.ytimg.com/yts/img/favicon_32-vflOogEID.png", icons[16].url.absoluteString)
        XCTAssertEqual(IconType.appleOSXSafariTab.rawValue, icons[16].type.rawValue)
        XCTAssertEqual(32, icons[16].width!)
        XCTAssertEqual(32, icons[16].height!)
        
        XCTAssertEqual("https://s.ytimg.com/yts/img/favicon_48-vflVjB_Qk.png", icons[17].url.absoluteString)
        XCTAssertEqual(IconType.classic.rawValue, icons[17].type.rawValue)
        XCTAssertEqual(48, icons[17].width!)
        XCTAssertEqual(48, icons[17].height!)
        
        XCTAssertEqual("https://s.ytimg.com/yts/img/favicon_96-vflW9Ec0w.png", icons[18].url.absoluteString)
        XCTAssertEqual(IconType.googleTV.rawValue, icons[18].type.rawValue)
        XCTAssertEqual(96, icons[18].width!)
        XCTAssertEqual(96, icons[18].height!)
        
        XCTAssertEqual("https://s.ytimg.com/yts/img/favicon_144-vfliLAfaB.png", icons[19].url.absoluteString)
        XCTAssertEqual(IconType.classic.rawValue, icons[19].type.rawValue)
        XCTAssertEqual(144, icons[19].width!)
        XCTAssertEqual(144, icons[19].height!)
        
        XCTAssertEqual("https://localhost/content/images/mstile-144x144.png", icons[20].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[20].type.rawValue)
        XCTAssertEqual(144, icons[20].width!)
        XCTAssertEqual(144, icons[20].height!)

        XCTAssertEqual("https://localhost/tile-tiny.png", icons[21].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[21].type.rawValue)
        XCTAssertEqual(70, icons[21].width!)
        XCTAssertEqual(70, icons[21].height!)

        XCTAssertEqual("https://localhost/tile-square.png", icons[22].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[22].type.rawValue)
        XCTAssertEqual(150, icons[22].width!)
        XCTAssertEqual(150, icons[22].height!)

        XCTAssertEqual("https://localhost/tile-wide.png", icons[23].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[23].type.rawValue)
        XCTAssertEqual(310, icons[23].width!)
        XCTAssertEqual(150, icons[23].height!)

        XCTAssertEqual("https://localhost/tile-large.png", icons[24].url.absoluteString)
        XCTAssertEqual(IconType.microsoftPinnedSite.rawValue, icons[24].type.rawValue)
        XCTAssertEqual(310, icons[24].width!)
        XCTAssertEqual(310, icons[24].height!)

        XCTAssertEqual("https://www.facebook.com/images/fb_icon_325x325.png", icons[25].url.absoluteString)
        XCTAssertEqual(IconType.openGraphImage.rawValue, icons[25].type.rawValue)
        XCTAssertNil(icons[25].width)
        XCTAssertNil(icons[25].height)
    }

    func testIssue6_ContentTypeWithEmptyComponent() {
        let result = parseHTTPContentType("text/html;;charset=UTF-8")

        XCTAssertEqual("text/html", result.mimeType)
        XCTAssertEqual(String.Encoding.utf8, result.encoding)
    }
    
    func testIssue20_EmptyXML() {
        let document = XMLDocument(string: "")
        
        XCTAssertEqual(0, document.children.count)
        XCTAssertEqual(0, document.query(xpath: "/BrowserConfig").count)
        XCTAssertEqual(0, document.query(xpath: "").count)
    }
    
    func testIssue23_InvalidXMLDoesNotCrash() {
        let document = XMLDocument(string: "<not valid xml!!!")

        XCTAssertEqual(0, document.children.count)
        XCTAssertEqual(0, document.query(xpath: "/BrowserConfig").count)
        XCTAssertEqual(0, document.query(xpath: "").count)
    }
    
    private func pathForTestBundleResource(fileName: String) -> String {
        let testBundle = Bundle(for: FavIconTests.self)
        return testBundle.path(forResource: fileName, ofType: "")!
    }

    private func stringForContentsOfFile(filePath: String, encoding: String.Encoding = String.Encoding.utf8) -> String? {
        return try? String(contentsOfFile: filePath, encoding: encoding) as String
    }
}
