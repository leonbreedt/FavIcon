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

enum DownloadResult {
    case text(value: String, mimeType: String, actualURL: URL)
    case binary(data: Data, mimeType: String, actualURL: URL)
    case exists
    case error(Error)
}

enum DownloadError: Error {
    case invalidResponse
    case emptyResponse
    case invalidTextResponse
    case notFound
    case serverError(code: Int)
}

private let downloadSession = URLSession(configuration: .ephemeral)

func downloadURLs(_ urls: [URL], method: String = "GET", completion: @escaping ([DownloadResult]) -> Void) {
    let dispatchGroup = DispatchGroup()

    var results = [(index: Int, result: DownloadResult)]()
    let addResult: (Int, DownloadResult) -> Void = { (index: Int, result: DownloadResult) in
        DispatchQueue.main.async {
            results.append((index: index, result: result))
        }
    }

    for (index, url) in urls.enumerated() {
        dispatchGroup.enter()

        var request = URLRequest(url: url)
        request.httpMethod = method
        let task = downloadSession.dataTask(with: request) { data, response, error in
            defer {
                dispatchGroup.leave()
            }

            guard error == nil else {
                addResult(index, .error(error!))
                return
            }

            guard let response = response else {
                addResult(index, .error(DownloadError.invalidResponse))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    addResult(index, .error(DownloadError.notFound))
                    return
                }

                if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                    addResult(index, .error(DownloadError.serverError(code: httpResponse.statusCode)))
                    return
                }

                if method.lowercased() == "head" {
                    addResult(index, .exists)
                    return
                }
            }

            if let data = data {
                let mimeType = response.mimeType ?? "application/octet-stream"
                let encoding: String.Encoding = response.textEncodingName != nil
                    ? parseStringEncoding(response.textEncodingName!) ?? .utf8
                    : .utf8
                if mimeType.starts(with: "text/") || mimeType == "application/json" {
                    guard let text = String(data: data, encoding: encoding) else {
                        addResult(index, .error(DownloadError.invalidTextResponse))
                        return
                    }
                    addResult(index, .text(value: text, mimeType: mimeType, actualURL: response.url!))
                    return
                } else {
                    addResult(index, .binary(data: data, mimeType: mimeType, actualURL: response.url!))
                    return
                }
            } else {
                addResult(index, .error(DownloadError.emptyResponse))
                return
            }
        }

        task.resume()
    }

    dispatchGroup.notify(queue: .main) {
        let sortedResults =
            results
                .sorted(by: { $0.index < $1.index })
                .map { $0.result }
        completion(sortedResults)
    }
}

func downloadURL(_ url: URL, method: String = "GET", completion: @escaping (DownloadResult) -> Void) {
    downloadURLs([url], method: method) { results in
        completion(results.first!)
    }
}
