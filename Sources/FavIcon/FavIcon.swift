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

#if os(iOS)
    import UIKit
    public typealias ImageType = UIImage
#elseif os(OSX)
    import Cocoa
    public typealias ImageType = NSImage
#endif

public enum IconDownloadResult {
    case success(image: ImageType)
    case failure(error: Error)
}

enum IconError: Error {
    case invalidBaseURL
    case atLeastOneOneIconRequired
    case invalidDownloadResponse
    case noIconsDetected
    case corruptImage
}

public final class FavIcon {
    public static func scan(_ url: URL,
                            completion: @escaping ([Icon]) -> Void) {
        let htmlURL = url
        let favIconURL = URL(string: "/favicon.ico", relativeTo: url as URL)!.absoluteURL

        var icons = [Icon]()
        let group = DispatchGroup()

        group.enter()
        downloadURL(favIconURL, method: "HEAD") { result in
            defer { group.leave() }
            switch result {
            case .exists:
                icons.append(Icon(url: favIconURL, type: .classic))
            default:
                return
            }
        }

        group.enter()
        downloadURL(htmlURL) { result in
            defer { group.leave() }
            if case .text(let text, let mimeType, let downloadedURL) = result {
                guard mimeType == "text/html" else { return }
                guard let data = text.data(using: .utf8) else { return }

                let document = HTMLDocument(data: data)

                icons.append(contentsOf: detectHTMLHeadIcons(document, baseURL: downloadedURL))
                for manifestURL in extractWebAppManifestURLs(document, baseURL: downloadedURL) {
                    group.enter()
                    downloadURL(manifestURL) { result in
                        defer { group.leave() }
                        if case .text(let text, _, let downloadedURL) = result {
                            icons.append(contentsOf: detectWebAppManifestIcons(text, baseURL: downloadedURL))
                        }
                    }
                }

                let browserConfigResult = extractBrowserConfigURL(document, baseURL: url)
                if let browserConfigURL = browserConfigResult.url, !browserConfigResult.disabled {
                    group.enter()
                    downloadURL(browserConfigURL) { result in
                        defer { group.leave() }
                        if case .text(let text, _, let downloadedURL) = result {
                            let document = XMLDocument(string: text)
                            icons.append(contentsOf: detectBrowserConfigXMLIcons(document, baseURL: downloadedURL))
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            completion(icons)
        }
    }

    public static func scan(_ url: String, completion: @escaping ([Icon]) -> Void) throws {
        guard let url = URL(string: url) else { throw IconError.invalidBaseURL }
        scan(url, completion: completion)
    }

    public static func download(_ icons: [Icon],
                                completion: @escaping ([IconDownloadResult]) -> Void) {
        let urls = icons.map { $0.url }
        downloadURLs(urls) { results in
            DispatchQueue.main.async {
                let downloadResults: [IconDownloadResult] = results.map { result in
                    switch result {
                    case .binary(let data, _, _):
                        if let image = ImageType(data: data) {
                            return .success(image: image)
                        } else {
                            return .failure(error: IconError.corruptImage)
                        }
                    case .error(let error):
                        return .failure(error: error)
                    default:
                        return .failure(error: IconError.invalidDownloadResponse)
                    }
                }

                completion(downloadResults)
            }
        }
    }

    public static func downloadAll(_ url: URL, completion: @escaping ([IconDownloadResult]) -> Void) {
        scan(url) { icons in
            download(icons, completion: completion)
        }
    }

    public static func downloadAll(_ url: String, completion: @escaping ([IconDownloadResult]) -> Void) throws {
        guard let url = URL(string: url) else { throw IconError.invalidBaseURL }
        downloadAll(url, completion: completion)
    }

    public static func downloadPreferred(_ url: URL,
                                         width: Int? = nil,
                                         height: Int? = nil,
                                         completion: @escaping (IconDownloadResult) -> Void) throws {
        scan(url) { icons in
            guard let icon = chooseIcon(icons, width: width, height: height) else {
                DispatchQueue.main.async {
                    completion(.failure(error: IconError.noIconsDetected))
                }
                return
            }

            download([icon]) { results in
                let downloadResult: IconDownloadResult
                if results.count > 0 {
                    downloadResult = results[0]
                } else {
                    downloadResult = .failure(error: IconError.noIconsDetected)
                }

                DispatchQueue.main.async {
                    completion(downloadResult)
                }
            }
        }
    }

    public static func downloadPreferred(_ url: String,
                                         width: Int? = nil,
                                         height: Int? = nil,
                                         completion: @escaping (IconDownloadResult) -> Void) throws {
        guard let url = URL(string: url) else { throw IconError.invalidBaseURL }
        try downloadPreferred(url, width: width, height: height, completion: completion)
    }

    static func chooseIcon(_ icons: [Icon], width: Int? = nil, height: Int? = nil) -> Icon? {
        guard icons.count > 0 else { return nil }

        let iconsInPreferredOrder = icons.sorted { left, right in
            if let preferredWidth = width, let preferredHeight = height,
                let widthLeft = left.width, let heightLeft = left.height,
                let widthRight = right.width, let heightRight = right.height {
                // Which is closest to preferred size?
                let deltaA = abs(widthLeft - preferredWidth) * abs(heightLeft - preferredHeight)
                let deltaB = abs(widthRight - preferredWidth) * abs(heightRight - preferredHeight)
                return deltaA < deltaB
            } else {
                if let areaLeft = left.area, let areaRight = right.area {
                    // Which is larger?
                    return areaRight < areaLeft
                }
            }

            if left.area != nil {
                // Only A has dimensions, prefer it.
                return true
            }
            if right.area != nil {
                // Only B has dimensions, prefer it.
                return false
            }

            // Neither has dimensions, order by enum value
            return left.type.rawValue < right.type.rawValue
        }

        return iconsInPreferredOrder.first!
    }
}

extension Icon {
    var area: Int? {
        if let width = width, let height = height {
            return width * height
        }
        return nil
    }
}

