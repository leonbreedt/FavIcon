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

// Attempts to download the text content for a URL, and returns
// `URLResult.TextDownloaded` as the result if it does.
class DownloadTextOperation: URLRequestOperation {
    override func processResult(data: NSData?, response: NSHTTPURLResponse, completion: URLResult -> Void) {
        let (mimeType, encoding) = response.contentTypeAndEncoding()
        switch mimeType {
        case "application/json", hasPrefix("text/"):
            if let data = data, let text = String(data: data, encoding: encoding ?? NSUTF8StringEncoding) {
                completion(.TextDownloaded(url: response.URL!, text: text, mimeType: mimeType))
            } else {
                completion(.Failed(error: URLRequestError.InvalidTextEncoding))
            }
            return
        default:
            completion(.Failed(error: URLRequestError.NotPlainText))
            return
        }
    }
}
