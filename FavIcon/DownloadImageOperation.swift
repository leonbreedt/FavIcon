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

// Attempts to download the image content for a URL, and returns
// `URLResult.ImageDownloaded` as the result if the
// download was successful, and the data is in an image format
// supported by the platform's image class.
class DownloadImageOperation: URLRequestOperation {
    override func processResult(data: NSData?, response: NSHTTPURLResponse, completion: URLResult -> Void) {
        guard let data = data else {
            completion(.Failed(error: URLRequestError.MissingResponse))
            return
        }

        let (mimeType, _) = response.contentTypeAndEncoding()
        switch mimeType {
        case "image/png", "image/jpg", "image/jpeg", "image/x-icon":
            // UIImage(data:) is not thread-safe and needs to run on main queue :/
            dispatch_async(dispatch_get_main_queue()) {
                var result: URLResult
                if let image = ImageType(data: data) {
                    result = .ImageDownloaded(url: response.URL!, image: image)
                } else {
                    result = .Failed(error: URLRequestError.UnsupportedImageFormat(mimeType: mimeType))
                }
                completion(result)
            }
            return
        default:
            completion(.Failed(error: URLRequestError.UnsupportedImageFormat(mimeType: mimeType)))
            return
        }
    }
}
