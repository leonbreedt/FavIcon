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

import Foundation

private let iconSizeTypeHints: [IconSize: IconType] = [
    IconSize(width: 16, height: 16): .classic,
    IconSize(width: 32, height: 32): .appleOSXSafariTab,
    IconSize(width: 96, height: 96): .googleTV,
    IconSize(width: 192, height: 192): .googleAndroidChrome,
    IconSize(width: 196, height: 196): .googleAndroidChrome
]

private let microsoftSizeHints: [String: IconSize] = [
    "msapplication-tileimage": IconSize(width: 144, height: 144),
    "msapplication-square70x70logo": IconSize(width: 70, height: 70),
    "msapplication-square150x150logo": IconSize(width: 150, height: 150),
    "msapplication-wide310x150logo": IconSize(width: 310, height: 150),
    "msapplication-square310x310logo": IconSize(width: 310, height: 310)
]

func detectHTMLHeadIcons(_ document: HTMLDocument, baseURL: URL) -> [Icon] {
    var icons = [Icon]()

    for link in document.query(xpath: "/html/head/link") {
        guard let rel = link.attributes["rel"] else { continue }
        guard let href = link.attributes["href"] else { continue }
        guard let url = URL(string: href, relativeTo: baseURL)?.absoluteURL else { continue }

        switch rel.lowercased() {
        case "shortcut icon":
            icons.append(Icon(url: url.absoluteURL, type: .shortcut))
        case "icon":
            guard let type = link.attributes["type"] else { continue }
            guard type.lowercased() == "image/png" else { continue }
            let sizes = parseHTMLIconSizes(link.attributes["sizes"])
            if sizes.count > 0 {
                for size in sizes {
                    guard let type = iconSizeTypeHints[size] else { continue }
                    icons.append(Icon(url: url, type: type, width: size.width, height: size.height))
                }
            } else {
                icons.append(Icon(url: url.absoluteURL, type: .classic))
            }
        case "apple-touch-icon",
             "apple-touch-icon-precomposed":
            let sizes = parseHTMLIconSizes(link.attributes["sizes"])
            if sizes.count > 0 {
                for size in sizes {
                    icons.append(Icon(url: url, type: .appleIOSWebClip, width: size.width, height: size.height))
                }
            } else {
                icons.append(Icon(url: url.absoluteURL, type: .appleIOSWebClip, width: 60, height: 60))
            }
        default:
            break
        }
    }

    for meta in document.query(xpath: "/html/head/meta") {
        guard let name = meta.attributes["name"]?.lowercased() else { continue }
        guard let content = meta.attributes["content"] else { continue }
        guard let url = URL(string: content, relativeTo: baseURL) else { continue }
        guard let size = microsoftSizeHints[name] else { continue }

        icons.append(Icon(url: url, type: .microsoftPinnedSite, width: size.width, height: size.height))
    }

    return icons
}

func extractWebAppManifestURLs(_ document: HTMLDocument, baseURL: URL) -> [URL] {
    var urls: [URL] = []
    for link in document.query(xpath: "/html/head/link") {
        guard let rel = link.attributes["rel"]?.lowercased() else { continue }
        guard rel == "manifest" else { continue }
        guard let href = link.attributes["href"] else { continue }
        guard let manifestURL = URL(string: href, relativeTo: baseURL) else { continue }

        urls.append(manifestURL)
    }
    return urls
}

func detectWebAppManifestIcons(_ json: String, baseURL: URL) -> [Icon] {
    var icons: [Icon] = []

    guard let data = json.data(using: .utf8) else { return icons }
    guard let object = try? JSONSerialization.jsonObject(with: data, options: []) else {
        return icons
    }
    guard let manifest = object as? [String: Any] else { return icons }
    guard let manifestIcons = manifest["icons"] as? [[String: Any]] else { return icons }

    for icon in manifestIcons {
        guard let type = icon["type"] as? String else { continue }
        guard type.lowercased() == "image/png" else { continue }
        guard let src = icon["src"] as? String else { continue }
        guard let sizeValues = icon["sizes"] as? String else { continue }
        guard let url = URL(string: src, relativeTo: baseURL)?.absoluteURL else { continue }

        let sizes = parseHTMLIconSizes(sizeValues)
        if sizes.count > 0 {
            for size in sizes {
                icons.append(Icon(url: url, type: .webAppManifest, width: size.width, height: size.height))
            }
        } else {
            icons.append(Icon(url: url, type: .webAppManifest))
        }
    }

    return icons
}

func extractBrowserConfigURL(_ document: HTMLDocument, baseURL: URL) -> (url: URL?, disabled: Bool) {
    for meta in document.query(xpath: "/html/head/meta") {
        guard let name = meta.attributes["name"]?.lowercased() else { continue }
        guard name == "msapplication-config" else { continue }
        guard let content = meta.attributes["content"] else { continue }
        if content.lowercased() == "none" {
            // Explicitly asked us not to download the file.
            return (url: nil, disabled: true)
        } else {
            return (url: URL(string: content, relativeTo: baseURL)?.absoluteURL, disabled: false)
        }
    }
    return (url: nil, disabled: false)
}

func detectBrowserConfigXMLIcons(_ document: XMLDocument, baseURL: URL) -> [Icon] {
    var icons: [Icon] = []

    for tile in document.query(xpath: "/browserconfig/msapplication/tile/*") {
        guard let src = tile.attributes["src"] else { continue }
        guard let url = URL(string: src, relativeTo: baseURL)?.absoluteURL else { continue }

        switch tile.name.lowercased() {
        case "tileimage":
            icons.append(Icon(url: url, type: .microsoftPinnedSite, width: 144, height: 144))
        case "square70x70logo":
            icons.append(Icon(url: url, type: .microsoftPinnedSite, width: 70, height: 70))
        case "square150x150logo":
            icons.append(Icon(url: url, type: .microsoftPinnedSite, width: 150, height: 150))
        case "wide310x150logo":
            icons.append(Icon(url: url, type: .microsoftPinnedSite, width: 310, height: 150))
        case "square310x310logo":
            icons.append(Icon(url: url, type: .microsoftPinnedSite, width: 310, height: 310))
        default:
            break
        }
    }

    return icons
}

private func parseHTMLIconSizes(_ string: String?) -> [IconSize] {
    var sizes: [IconSize] = []
    if let string = string?.lowercased(), string != "any" {
        for size in string.components(separatedBy: .whitespaces) {
            let parts = size.components(separatedBy: "x")
            if parts.count != 2 { continue }
            if let width = Int(parts[0]), let height = Int(parts[1]) {
                sizes.append(IconSize(width: width, height: height))
            }
        }
    }
    return sizes
}

extension IconSize: Hashable {
    var hashValue: Int {
        return width.hashValue ^ height.hashValue
    }
}

private func == (lhs: IconSize, rhs: IconSize) -> Bool {
    return lhs.width == rhs.width && lhs.height == rhs.height
}

private struct IconSize {
    let width: Int
    let height: Int
}



