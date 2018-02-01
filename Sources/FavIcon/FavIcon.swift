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

public final class FavIcon {
    public static func scan(_ url: URL, completion: @escaping ([Icon]) -> Void) {
        let htmlURL = url
        let favIconURL = URL(string: "/favicon.ico", relativeTo: url as URL)!.absoluteURL

        var icons = [Icon]()
        let group = DispatchGroup()

        group.enter()
        download(url: favIconURL, method: "HEAD") { result in
            defer { group.leave() }
            switch result {
            case .exists:
                icons.append(Icon(url: favIconURL, type: .classic))
            default:
                return
            }
        }

        group.enter()
        download(url: htmlURL) { result in
            defer { group.leave() }
            if case .text(let text, let mimeType, let downloadedURL) = result {
                guard mimeType == "text/html" else { return }
                guard let data = text.data(using: .utf8) else { return }

                let document = HTMLDocument(data: data)

                icons.append(contentsOf: detectHTMLHeadIcons(document, baseURL: downloadedURL))
                for manifestURL in extractWebAppManifestURLs(document, baseURL: downloadedURL) {
                    group.enter()
                    download(url: manifestURL) { result in
                        defer { group.leave() }
                        if case .text(let text, _, let downloadedURL) = result {
                            icons.append(contentsOf: detectWebAppManifestIcons(text, baseURL: downloadedURL))
                        }
                    }
                }

                let browserConfigResult = extractBrowserConfigURL(document, baseURL: url)
                if let browserConfigURL = browserConfigResult.url, !browserConfigResult.disabled {
                    group.enter()
                    download(url: browserConfigURL) { result in
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
}

