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

import Foundation

/// Enumerates the types of detected icons.
public enum DetectedIconType : UInt {
    /// A shortcut icon.
    case Shortcut
    /// A classic favicon style icon (usually in the range 16x16 to 48x48).
    case FavIcon
    /// A Google TV icon.
    case GoogleTV
    /// An icon used by Chrome on Android
    case GoogleAndroidChrome
    /// An icon used by Safari on OS X.
    case AppleOSXSafariTabIcon
    /// An icon used iOS for Web Clips on home screen.
    case AppleIOSWebClip
}

/// Represents a detected icon.
public struct DetectedIcon {
    /// The absolute URL for the icon file.
    let url: NSURL
    /// The type of the icon.
    let type: DetectedIconType
    /// The width of the icon, if known, in pixels.
    let width: Int?
    /// The height of the icon, if known, in pixels.
    let height: Int?
    
    init(url: NSURL, type: DetectedIconType, width: Int? = nil, height: Int? = nil) {
        self.url = url
        self.type = type
        self.width = width
        self.height = height
    }
}

#if os(iOS)
    import UIKit
    /// iOS image type (`UIImage`).
    public typealias ImageType = UIImage
#elseif os(OSX)
    import Cocoa
    /// OS X image type (`NSImage`).
    public typealias ImageType = NSImage
#endif

/// Represents the result of attempting to download an icon.
public enum IconDownloadResult {
    /// Download successful.
    /// - Parameters:
    ///   - image: The `ImageType` for the downloaded icon.
    case Success(image: ImageType)
    /// Download failed for some reason.
    /// - Parameters:
    ///   - error: The error which can be consulted to determine the root cause.
    case Failure(error: ErrorType)
}

/// Responsible for detecting all of the different icons supported by a given site.
public class FavIcons {
    /// Interrogates a base URL, attempting to determine all of the supported icons.
    /// It will check whether known file names exist, and if present, it will parse 
    /// the Google and Microsoft specific JSON and XML files to find files if necessary. 
    /// It will also attempt to parse the response of the `url` as HTML to try and find 
    /// relevant `<link>` elements.
    ///
    /// - Parameters:
    ///   - url: The URL to interrogate for the presence of icons.
    ///   - completion: The callback to invoke when detection has completed. The caller
    ///                 must not make any assumptions about which dispatch queue the completion
    ///                 will be invoked on.
    /// - Returns: The list of `DetectedIcon`s representing the icons that were found.
    public static func detect(url: NSURL, completion: [DetectedIcon] -> Void) {
        let operations = [
            DownloadTextOperation(url: url),
            CheckURLExistsOperation(url: NSURL(string: "/favicon.ico", relativeToURL: url)!.absoluteURL)
        ]
        
        executeURLOperations(operations) { results in
            var icons: [DetectedIcon] = []
            
            switch results[0] {
            case .TextDownloaded(let actualURL, let text, let contentType):
                if contentType == "text/html" {
                    icons.appendContentsOf(extractHTMLHeadIcons(HTMLDocument(string: text), baseURL: actualURL))
                }
                break
            default: break
            }
            
            switch results[1] {
            case .Success(let actualURL):
                icons.append(DetectedIcon(url: actualURL, type: .FavIcon))
                break
            default: break
            }
            
            completion(icons)
        }
    }
    
    /// Downloads all available icons.
    /// - Parameters:
    ///   - url: The URL to interrogate for the presence of icons.
    ///   - completion: A completion handler to invoke when the download results are available. This can be called on any queue.
    public static func download(url: NSURL, completion: [IconDownloadResult] -> Void) {
        detect(url) { icons in
            let operations: [DownloadImageOperation] = icons.map { DownloadImageOperation(url: $0.url) }
            
            executeURLOperations(operations) { results in
                let downloadResults: [IconDownloadResult] = results.map { result in
                    switch result {
                    case .ImageDownloaded(_, let image):
                        return IconDownloadResult.Success(image: image)
                    case .Failed(let error):
                        return IconDownloadResult.Failure(error: error)
                    default:
                        return IconDownloadResult.Failure(error: IconError.InvalidDownloadResponse)
                    }
                }
                
                completion(downloadResults)
            }
        }
    }
    
    /// Downloads the most preferred icon out of the available icons.
    /// - Parameters:
    ///   - url: The URL to interrogate for the presence of icons.
    ///   - preferredWidth: The preferred icon width, in pixels.
    ///   - preferredHeight: The preferred icon height, in pixels.
    ///   - completion: A completion handler to invoke when the download result is available. This can be called on any queue.
    public static func download(url: NSURL, preferredWidth: Int, preferredHeight: Int, completion: IconDownloadResult -> Void) throws {
        detect(url) { icons in
            if icons.count == 0 {
                completion(IconDownloadResult.Failure(error: IconError.NoIconsDetected))
                return
            }
            
            let rankedIcons = icons.sort { a, b in
                if let sizeA = a.dimensions, let sizeB = b.dimensions {
                    let isWidthACloser = abs(preferredWidth - sizeA.width) < abs(preferredWidth - sizeB.width)
                    let isHeightACloser = abs(preferredHeight - sizeA.height) < abs(preferredHeight - sizeB.height)
                    return isWidthACloser && isHeightACloser
                }
                if let _ = a.dimensions {
                    return true
                }
                
                if let _ = b.dimensions {
                    return false
                }

                switch a.type {
                case .Shortcut:
                    switch b.type {
                    case .FavIcon: return true
                    default: return false
                    }
                default: return false
                }
            }
            
            let icon = rankedIcons.first!
            
            executeURLOperations([DownloadImageOperation(url: icon.url)]) { results in
                let downloadResults: [IconDownloadResult] = results.map { result in
                    switch result {
                    case .ImageDownloaded(_, let image):
                        return IconDownloadResult.Success(image: image)
                    case .Failed(let error):
                        return IconDownloadResult.Failure(error: error)
                    default:
                        return IconDownloadResult.Failure(error: IconError.InvalidDownloadResponse)
                    }
                }
                
                assert(downloadResults.count > 0)
                
                completion(downloadResults.first!)
            }
        }
    }
    
    /// Executes an array of URL operations in parallel on a background queue, and execute a completion
    /// block when they have all finished.
    /// - Parameters:
    ///   - operations: An array of `NSOperation` instances to execute.
    ///   - concurrency: The maximum number of operations to execute concurrently.
    ///   - completion: A completion handler to invoke when all operations have completed. This can be called on any queue.
    private static func executeURLOperations(operations: [URLRequestOperation], concurrency: Int = 2, completion: [URLResult] -> Void) {
        guard operations.count > 0 else {
            completion([])
            return
        }
        
        let queue = NSOperationQueue()
        queue.suspended = true
        queue.maxConcurrentOperationCount = concurrency
        
        let completionOperation = NSBlockOperation {
            completion(operations.map { $0.result! })
        }
        
        for operation in operations {
            queue.addOperation(operation)
            completionOperation.addDependency(operation)
        }
        
        queue.addOperation(completionOperation)
        
        queue.suspended = false
    }
    
    /// Extracts a list of icons from the `<head>` section of an HTML document.
    static func extractHTMLHeadIcons(document: HTMLDocument, baseURL: NSURL) -> [DetectedIcon] {
        var icons: [DetectedIcon] = []
        
        for link in document.query("/html/head/link") {
            if let rel = link.attributes["rel"], href = link.attributes["href"], url = NSURL(string: href, relativeToURL: baseURL) {
                switch rel.lowercaseString {
                case "shortcut icon":
                    icons.append(DetectedIcon(url: url.absoluteURL, type:.Shortcut))
                    break
                case "icon":
                    if let type = link.attributes["type"] where type.lowercaseString == "image/png" {
                        let sizes = parseHTMLIconSizes(link.attributes["sizes"])
                        if sizes.count > 0 {
                            for size in sizes {
                                switch size {
                                case (16, 16):
                                    icons.append(DetectedIcon(url: url.absoluteURL, type: .FavIcon, width: size.width, height: size.height))
                                    break
                                case (32, 32):
                                    icons.append(DetectedIcon(url: url.absoluteURL, type: .AppleOSXSafariTabIcon, width: size.width, height: size.height))
                                    break
                                case (96, 96):
                                    icons.append(DetectedIcon(url: url.absoluteURL, type: .GoogleTV, width: size.width, height: size.height))
                                    break
                                case (192, 192), (196, 196):
                                    icons.append(DetectedIcon(url: url.absoluteURL, type: .GoogleAndroidChrome, width: size.width, height: size.height))
                                    break
                                default:
                                    break
                                }
                            }
                        } else {
                            icons.append(DetectedIcon(url: url.absoluteURL, type: .FavIcon))
                        }
                    }
                case "apple-touch-icon":
                    let sizes = parseHTMLIconSizes(link.attributes["sizes"])
                    if sizes.count > 0 {
                        for size in sizes {
                            icons.append(DetectedIcon(url: url.absoluteURL, type: .AppleIOSWebClip, width: size.width, height: size.height))
                        }
                    } else {
                        icons.append(DetectedIcon(url: url.absoluteURL, type: .AppleIOSWebClip, width: 60, height: 60))
                    }
                default:
                    break
                }
            }
        }
        
        return icons
    }
    
    private static func parseHTMLIconSizes(string: String?) -> [(width: Int, height: Int)] {
        var sizes: [(width: Int, height: Int)] = []
        if let string = string?.lowercaseString where string != "any" {
            for size in string.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) {
                let parts = size.componentsSeparatedByString("x")
                if parts.count != 2 { continue }
                if let width = Int(parts[0]), let height = Int(parts[1]) {
                    sizes.append((width: width, height: height))
                }
            }
        }
        return sizes
    }
    
    private init () {
    }
}

/// Enumerates errors that can be thrown while detecting or downloading icons.
public enum IconError : ErrorType {
    /// The base URL specified is not a valid URL.
    case InvalidBaseURL
    /// At least one icon to must be specified for downloading.
    case AtLeastOneOneIconRequired
    /// Unexpected response when downloading
    case InvalidDownloadResponse
    /// No icons were detected, so nothing could be downloaded.
    case NoIconsDetected
}

extension FavIcons {
    public static func detect(url urlString: String, completion: [DetectedIcon] -> Void) throws {
        guard let url = NSURL(string: urlString) else { throw IconError.InvalidBaseURL }
        detect(url, completion: completion)
    }

    public static func download(url urlString: String, completion: [IconDownloadResult] -> Void) throws {
        guard let url = NSURL(string: urlString) else { throw IconError.InvalidBaseURL }
        download(url, completion: completion)
    }
}

extension DetectedIcon {
    /// The dimensions of a detected icon, if known.
    var dimensions: (width: Int, height: Int)? {
        if let width = width, height = height {
            return (width: width, height: height)
        }
        return nil
    }
}

/// Enumerates the possible results of a `URLRequestOperation`.
enum URLResult {
    /// Plain text content was downloaded successfully.
    /// - Parameters:
    ///   - url: The actual URL the content was downloaded from, after any redirects.
    ///   - text: The text content.
    ///   - mimeType: The MIME type of the text content (e.g. `application/json`).
    case TextDownloaded(url: NSURL, text: String, mimeType: String)
    /// Image content was downloaded successfully.
    /// - Parameters:
    ///   - url: The actual URL the content was downloaded from, after any redirects.
    ///   - image: The downloaded image.
    case ImageDownloaded(url: NSURL, image: ImageType)
    /// The URL request was successful (HTTP 200 response).
    /// - Parameters:
    ///   - url: The actual URL, after any redirects.
    case Success(url: NSURL)
    /// The URL request failed for some reason.
    /// - Parameters:
    ///   - error: The error that occurred.
    case Failed(error: ErrorType)
}

/// Enumerates well known errors that may occur while executing a `URLRequestOperation`.
enum URLRequestError : ErrorType {
    /// No response was received from the server.
    case MissingResponse
    /// The file was not found (HTTP 404 response).
    case FileNotFound
    /// The request succeeded, but the content was not plain text when it was expected to be.
    case NotPlainText
    /// The request succeeded, but the content encoding could not be determined, or was malformed.
    case InvalidTextEncoding
    /// The request succeeded, but the MIME type of the response is not a supported image format.
    case UnsupportedImageFormat(mimeType: String)
    /// An unexpected HTTP error response was returned.
    /// - Parameters:
    ///   - response: The `NSHTTPURLResponse` that can be consulted for further information.
    case HTTPError(response: NSHTTPURLResponse)
}

/// Checks whether a URL exists, and returns `URLResult.Success` as the result if it does.
class CheckURLExistsOperation : URLRequestOperation {
    override func prepareRequest() {
        urlRequest.HTTPMethod = "HEAD"
    }
    
    override func processResult(data: NSData?, response: NSHTTPURLResponse) -> URLResult {
        return .Success(url: response.URL!)
    }
}

/// Attempts to download the text content for a URL, and returns `URLResult.TextDownloaded` as the result if it does.
class DownloadTextOperation : URLRequestOperation {
    override func processResult(data: NSData?, response: NSHTTPURLResponse) -> URLResult {
        let (mimeType, encoding) = response.contentTypeAndEncoding()
        switch mimeType {
        case "application/json", hasPrefix("text/"):
            if let data = data, let text = String(data: data, encoding: encoding ?? NSUTF8StringEncoding) {
                return .TextDownloaded(url: response.URL!, text: text, mimeType: mimeType)
            }
            return .Failed(error: URLRequestError.InvalidTextEncoding)
        default:
            return .Failed(error: URLRequestError.NotPlainText)
        }
    }
}

class DownloadImageOperation : URLRequestOperation {
    override func processResult(data: NSData?, response: NSHTTPURLResponse) -> URLResult {
        guard let data = data else { return .Failed(error: URLRequestError.MissingResponse) }
        let (mimeType, _) = response.contentTypeAndEncoding()
        switch mimeType {
        case "image/png", "image/jpg", "image/jpeg", "image/x-icon":
            if let image = ImageType(data: data) {
                return .ImageDownloaded(url: response.URL!, image: image)
            }
        default:
            break
        }
        return .Failed(error: URLRequestError.UnsupportedImageFormat(mimeType: mimeType))
    }
}

/// Base class for performing URL requests in the context of an `NSOperation`.
class URLRequestOperation : NSOperation {
    let urlRequest: NSMutableURLRequest
    var result: URLResult?
    
    private var task: NSURLSessionDataTask?
    private let session: NSURLSession
    private var semaphore: dispatch_semaphore_t?
    
    init(url: NSURL, session: NSURLSession = NSURLSession.sharedSession()) {
        self.session = session
        self.urlRequest = NSMutableURLRequest(URL: url)
        self.semaphore = nil
    }
    
    override func main() {
        semaphore = dispatch_semaphore_create(0)
        prepareRequest()
        task = session.dataTaskWithRequest(urlRequest, completionHandler: dataTaskCompletion)
        task?.resume()
        dispatch_semaphore_wait(semaphore!, DISPATCH_TIME_FOREVER)
    }
    
    override func cancel() {
        task?.cancel()
        if let semaphore = semaphore {
            dispatch_semaphore_signal(semaphore)
        }
    }
    
    func prepareRequest() {
    }
    
    func processResult(data: NSData?, response: NSHTTPURLResponse) -> URLResult {
        fatalError("must override processResult()")
    }
    
    private func dataTaskCompletion(data: NSData?, response: NSURLResponse?, error: NSError?) {
        defer {
            if let semaphore = semaphore {
                dispatch_semaphore_signal(semaphore)
            }
        }
        
        guard error == nil else {
            result = .Failed(error: error!)
            return
        }
        
        guard let response = response as? NSHTTPURLResponse else {
            result = .Failed(error: URLRequestError.MissingResponse)
            return
        }
        
        if response.statusCode == 404 {
            result = .Failed(error: URLRequestError.FileNotFound)
            return
        }
        
        if response.statusCode < 200 || response.statusCode > 299 {
            result = .Failed(error: URLRequestError.HTTPError(response: response))
            return
        }
        
        result = processResult(data, response: response)
    }
}

// MARK: - Extensions

func ~=<T>(pattern: T -> Bool, value: T) -> Bool {
    return pattern(value)
}

func hasPrefix(prefix: String)(value: String) -> Bool {
    return value.hasPrefix(prefix)
}

extension String {
    /// Parses this string as an HTTP Content-Type header.
    func parseAsHTTPContentTypeHeader() -> (mimeType: String, encoding: UInt?) {
        let headerComponents = componentsSeparatedByString(";").map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
        if headerComponents.count > 1 {
            let parameters = headerComponents[1..<headerComponents.count]
                .map { $0.componentsSeparatedByString("=") }
                .toDictionary { ($0[0], $0[1]) }
            
            // Default according to RFC is ISO-8859-1, but probably nothing obeys that, so default
            // to UTF-8 instead.
            var encoding = NSUTF8StringEncoding
            if let charset = parameters["charset"], let parsedEncoding = charset.parseAsStringEncoding() {
                encoding = parsedEncoding
            }
            
            return (mimeType: headerComponents[0], encoding: encoding)
        } else {
            return (mimeType: headerComponents[0], encoding: nil)
        }
    }
    
    /// Returns identifier for the encoding.
    func parseAsStringEncoding() -> UInt? {
        switch self.lowercaseString {
        case "iso-8859-1", "latin1": return NSISOLatin1StringEncoding
        case "iso-8859-2", "latin2": return NSISOLatin2StringEncoding
        case "iso-2022-jp": return NSISO2022JPStringEncoding
        case "shift_jis": return NSShiftJISStringEncoding
        case "us-ascii": return NSASCIIStringEncoding
        case "utf-8": return NSUTF8StringEncoding
        case "utf-16": return NSUTF16StringEncoding
        case "utf-32": return NSUTF32StringEncoding
        case "utf-32be": return NSUTF32BigEndianStringEncoding
        case "utf-32le": return NSUTF32LittleEndianStringEncoding
        case "windows-1250": return NSWindowsCP1250StringEncoding
        case "windows-1251": return NSWindowsCP1251StringEncoding
        case "windows-1252": return NSWindowsCP1252StringEncoding
        case "windows-1253": return NSWindowsCP1253StringEncoding
        case "windows-1254": return NSWindowsCP1254StringEncoding
        case "x-mac-roman": return NSMacOSRomanStringEncoding
        default:
            return nil
        }
    }
}

extension NSHTTPURLResponse {
    func contentTypeAndEncoding() -> (mimeType: String, encoding: UInt?) {
        if let contentTypeHeader = allHeaderFields["Content-Type"] as? String {
            return contentTypeHeader.parseAsHTTPContentTypeHeader()
        }
        return (mimeType: "application/octet-stream", encoding: nil)
    }
}

extension Array {
    /// Converts this array to a dictionary of type `[K: V]`, by calling a transform function to
    /// obtain a key and a value from an array element.
    /// - Parameters:
    ///   - transform: A function that will transform an array element of type `Element` into a `(K, V)` tuple.
    func toDictionary<K, V>(transform: Element -> (K, V)) -> [K: V] {
        var dict: [K: V] = [:]
        for item in self {
            let (key, value) = transform(item)
            dict[key] = value
        }
        return dict
    }
}