//
// FavIcon
// Copyright © 2016 Leon Breedt
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

import Foundation

private let kRelIconTypeMap: [IconSize: DetectedIconType] = [
    IconSize(width: 16, height: 16): .Classic,
    IconSize(width: 32, height: 32): .AppleOSXSafariTab,
    IconSize(width: 96, height: 96): .GoogleTV,
    IconSize(width: 192, height: 192): .GoogleAndroidChrome,
    IconSize(width: 196, height: 196): .GoogleAndroidChrome
]

private let kMicrosoftSizeMap: [String: IconSize] = [
    "msapplication-tileimage": IconSize(width: 144, height: 144),
    "msapplication-square70x70logo": IconSize(width: 70, height: 70),
    "msapplication-square150x150logo": IconSize(width: 150, height: 150),
    "msapplication-wide310x150logo": IconSize(width: 310, height: 150),
    "msapplication-square310x310logo": IconSize(width: 310, height: 310),
]

// swiftlint:disable function_body_length

/// Extracts a list of icons from the `<head>` section of an HTML document.
///
/// - parameters:
///   - document: An HTML document to process.
///   - baseURL: A base URL to combine with any relative image paths.
/// - returns: An array of `DetectedIcon` structures.
func extractHTMLHeadIcons(document: HTMLDocument, baseURL: NSURL) -> [DetectedIcon] {
    var icons: [DetectedIcon] = []

    for link in document.query("/html/head/link") {
        if let rel = link.attributes["rel"],
               href = link.attributes["href"],
               url = NSURL(string: href, relativeToURL: baseURL) {
            switch rel.lowercaseString {
            case "shortcut icon":
                icons.append(DetectedIcon(url: url.absoluteURL, type:.Shortcut))
                break
            case "icon":
                if let type = link.attributes["type"] where type.lowercaseString == "image/png" {
                    let sizes = parseHTMLIconSizes(link.attributes["sizes"])
                    if sizes.count > 0 {
                        for size in sizes {
                            if let type = kRelIconTypeMap[size] {
                                icons.append(DetectedIcon(url: url,
                                                          type: type,
                                                          width: size.width,
                                                          height: size.height))
                            }
                        }
                    } else {
                        icons.append(DetectedIcon(url: url.absoluteURL, type: .Classic))
                    }
                }
            case "apple-touch-icon":
                let sizes = parseHTMLIconSizes(link.attributes["sizes"])
                if sizes.count > 0 {
                    for size in sizes {
                        icons.append(DetectedIcon(url: url.absoluteURL,
                                                  type: .AppleIOSWebClip,
                                                  width: size.width,
                                                  height: size.height))
                    }
                } else {
                    icons.append(DetectedIcon(url: url.absoluteURL,
                                              type: .AppleIOSWebClip,
                                              width: 60,
                                              height: 60))
                }
            default:
                break
            }
        }
    }

    for meta in document.query("/html/head/meta") {
        if let name = meta.attributes["name"]?.lowercaseString,
               content = meta.attributes["content"],
               url = NSURL(string: content, relativeToURL: baseURL),
               size = kMicrosoftSizeMap[name] {
            icons.append(DetectedIcon(url: url,
                                      type: .MicrosoftPinnedSite,
                                      width: size.width,
                                      height: size.height))
        }
    }

    return icons
}
// swiftlint:enable function_body_length

/// Extracts a list of icons from a Web Application Manifest file
///
/// - parameters:
///   - jsonString: A JSON string containing the contents of the manifest file.
///   - baseURL: A base URL to combine with any relative image paths.
/// - returns: An array of `DetectedIcon` structures.
func extractManifestJSONIcons(jsonString: String, baseURL: NSURL) -> [DetectedIcon] {
    var icons: [DetectedIcon] = []

    if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
        let object = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()),
        let manifest = object as? NSDictionary,
        let manifestIcons = manifest["icons"] as? [NSDictionary] {
            for icon in manifestIcons {
                if let type = icon["type"] as? String where type.lowercaseString == "image/png",
                    let src = icon["src"] as? String,
                    url = NSURL(string: src, relativeToURL: baseURL)?.absoluteURL {
                        let sizes = parseHTMLIconSizes(icon["sizes"] as? String)
                        if sizes.count > 0 {
                            for size in sizes {
                                icons.append(DetectedIcon(url: url,
                                    type: .WebAppManifest,
                                    width: size.width,
                                    height: size.height))
                            }
                        } else {
                            icons.append(DetectedIcon(url: url, type: .WebAppManifest))
                        }
                }
            }
    }

    return icons
}

/// Extracts a list of icons from a Microsoft browser configuration XML document.
///
/// - parameters:
///   - document: An `XMLDocument` for the Microsoft browser configuration file.
///   - baseURL: A base URL to combine with any relative image paths.
/// - returns: An array of `DetectedIcon` structures.
func extractBrowserConfigXMLIcons(document: XMLDocument, baseURL: NSURL) -> [DetectedIcon] {
    var icons: [DetectedIcon] = []

    for tile in document.query("/browserconfig/msapplication/tile/*") {
        if let src = tile.attributes["src"],
            let url = NSURL(string: src, relativeToURL: baseURL)?.absoluteURL {
                switch tile.name.lowercaseString {
                case "tileimage":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 144, height: 144))
                    break
                case "square70x70logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 70, height: 70))
                    break
                case "square150x150logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 150, height: 150))
                    break
                case "wide310x150logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 310, height: 150))
                    break
                case "square310x310logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 310, height: 310))
                    break
                default:
                    break
                }
        }
    }

    return icons
}

/// Extracts the Web App Manifest URLs from an HTML document, if any.
///
/// - parameters:
///   - document: The HTML document to scan for Web App Manifest URLs
///   - baseURL: The base URL that any 'href' attributes are relative to.
/// - returns: An array of Web App Manifest `NSURL`s.
func extractWebAppManifestURLs(document: HTMLDocument, baseURL: NSURL) -> [NSURL] {
    var urls: [NSURL] = []
    for link in document.query("/html/head/link") {
        if let rel = link.attributes["rel"]?.lowercaseString where rel == "manifest",
           let href = link.attributes["href"],
           let manifestURL = NSURL(string: href, relativeToURL: baseURL) {
            urls.append(manifestURL)
        }
    }
    return urls
}

/// Extracts the first browser config XML file URL from an HTML document, if any.
///
/// - parameters:
///   - document: The HTML document to scan for browser config XML file URLs.
///   - baseURL: The base URL that any 'href' attributes are relative to.
/// - returns: A named tuple describing the file URL or a flag indicating that the server
///            explicitly requested that the file not be downloaded.
func extractBrowserConfigURL(document: HTMLDocument, baseURL: NSURL) -> (url: NSURL?, disabled: Bool) {
    for meta in document.query("/html/head/meta") {
        if let name = meta.attributes["name"]?.lowercaseString where name == "msapplication-config",
           let content = meta.attributes["content"] {
            if content.lowercaseString == "none" {
                // Explicitly asked us not to download the file.
                return (url: nil, disabled: true)
            } else {
                return (url: NSURL(string: content, relativeToURL: baseURL)?.absoluteURL, disabled: false)
            }
        }
    }
    return (url: nil, disabled: false)
}

/// Represents an icon size.
struct IconSize {
    /// The width of the icon.
    let width: Int
    /// The height of the icon.
    let height: Int
}

/// Helper function for parsing a W3 `sizes` attribute value.
///
/// - parameters:
///   - string: If not `nil`, the value of the attribute to parse (e.g. `50x50 144x144`).
/// - returns: An array of `IconSize` structs for each size found.
private func parseHTMLIconSizes(string: String?) -> [IconSize] {
    var sizes: [IconSize] = []
    if let string = string?.lowercaseString where string != "any" {
        for size in string.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) {
            let parts = size.componentsSeparatedByString("x")
            if parts.count != 2 { continue }
            if let width = Int(parts[0]), let height = Int(parts[1]) {
                sizes.append(IconSize(width: width, height: height))
            }
        }
    }
    return sizes
}

extension IconSize : Hashable {
    var hashValue: Int {
        return width.hashValue ^ height.hashValue
    }
}

func == (lhs: IconSize, rhs: IconSize) -> Bool {
    return lhs.width == rhs.width && lhs.height == rhs.height
}
