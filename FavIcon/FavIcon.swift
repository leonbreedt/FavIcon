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

#if os(iOS)
    import UIKit
    typealias ImageType = UIImage
#elseif os(OSX)
    import Cocoa
    typealias ImageType = NSImage
#endif

/// Represents a detected icon.
public enum FavIconType {
    /// An icon referenced by a `<link rel="shortcut icon">` element.
    /// - Parameters:
    ///   - url: The URL the icon can be retrieved from.
    case ShortcutIcon(url: NSURL)
    /// A favicon.ico file.
    /// - Parameters:
    ///   - url: The URL the icon can be retrieved from.
    case FavIconICO(url: NSURL)
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
    /// - Returns: The list of `FavIcon` objects representing the icons that were found.
    public static func detect(url: NSURL, completion: [FavIconType] -> Void) {
        let queue = NSOperationQueue()
        queue.suspended = true
        queue.maxConcurrentOperationCount = 2 // Only 2 concurrent connections to server (be a good citizen).
        
        let baseURLTextOperation = DownloadTextOperation(url: url)
        let icoFileExistsOperation = CheckURLExistsOperation(url: NSURL(string: "/favicon.ico", relativeToURL: url)!.absoluteURL)
        let processResultsOperation = NSBlockOperation {
            var icons: [FavIconType] = []
            
            if let result = baseURLTextOperation.result {
                switch result {
                case .TextDownloaded(let actualURL, let text, let contentType):
                    if contentType == "text/html" {
                        for link in HTMLDocument(string: text).query("/html/head/link") {
                            if let rel = link.attributes["rel"], href = link.attributes["href"], url = NSURL(string: href, relativeToURL: actualURL) {
                                switch rel.lowercaseString {
                                case "shortcut icon":
                                    icons.append(.ShortcutIcon(url: url.absoluteURL))
                                    break
                                default:
                                    break
                                }
                            }
                        }
                    }
                    break
                default:
                    break
                }
            }
            if let result = icoFileExistsOperation.result {
                switch result {
                case .Success(let actualURL):
                    icons.append(.FavIconICO(url: actualURL))
                default:
                    break
                }
            }
            
            completion(icons)
        }
        
        processResultsOperation.addDependency(baseURLTextOperation)
        processResultsOperation.addDependency(icoFileExistsOperation)
        
        queue.addOperation(baseURLTextOperation)
        queue.addOperation(icoFileExistsOperation)
        queue.addOperation(processResultsOperation)
        
        queue.suspended = false
    }

    private init () {
    }
}

/// Enumerates errors that can be thrown while detecting icons.
public enum FavIconError : ErrorType {
    /// The base URL specified is not a valid URL.
    case InvalidBaseURL
}

extension FavIcons {
    public static func detect(url urlString: String, completion: [FavIconType] -> Void) throws {
        guard let url = NSURL(string: urlString) else { throw FavIconError.InvalidBaseURL }
        detect(url, completion: completion)
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
    
    override func processResult(data: NSData?, response: NSURLResponse?, error: NSError?) -> URLResult {
        guard error == nil else { return .Failed(error: error!)}
        guard let response = response as? NSHTTPURLResponse else { return .Failed(error: URLRequestError.MissingResponse) }
        if response.statusCode == 404 {
            return .Failed(error: URLRequestError.FileNotFound)
        }
        if response.statusCode < 200 || response.statusCode > 299 {
            return .Failed(error: URLRequestError.HTTPError(response: response))
        }
        return .Success(url: response.URL!)
    }
}

/// Attempts to download the text content for a URL, and returns `URLResult.TextDownloaded` as the result if it does.
class DownloadTextOperation : URLRequestOperation {
    override func processResult(data: NSData?, response: NSURLResponse?, error: NSError?) -> URLResult {
        guard error == nil else { return .Failed(error: error!)}
        guard let data = data, response = response as? NSHTTPURLResponse else { return .Failed(error: URLRequestError.MissingResponse) }
        
        if response.statusCode == 404 {
            return .Failed(error: URLRequestError.FileNotFound)
        }
        
        if response.statusCode < 200 || response.statusCode > 299 {
            return .Failed(error: URLRequestError.HTTPError(response: response))
        }
        
        var mimeType = "application/octet-stream"
        var encoding: UInt?
        if let contentTypeHeader = response.allHeaderFields["Content-Type"] as? String {
            let (type, enc) = contentTypeHeader.parseAsHTTPContentTypeHeader()
            mimeType = type
            encoding = enc
        }
        
        switch mimeType {
        case "application/json", hasPrefix("text/"):
            if let text = String(data: data, encoding: encoding ?? NSUTF8StringEncoding) {
                return .TextDownloaded(url: response.URL!, text: text, mimeType: mimeType)
            }
            return .Failed(error: URLRequestError.InvalidTextEncoding)
        default:
            return .Failed(error: URLRequestError.NotPlainText)
        }
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
    
    func processResult(data: NSData?, response: NSURLResponse?, error: NSError?) -> URLResult {
        fatalError("must override processResult()")
    }
    
    private func dataTaskCompletion(data: NSData?, response: NSURLResponse?, error: NSError?) {
        defer {
            if let semaphore = semaphore {
                dispatch_semaphore_signal(semaphore)
            }
        }
        
        result = processResult(data, response: response, error: error)
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
    func parseAsHTTPContentTypeHeader() -> (contentType: String, encoding: UInt?) {
        let headerComponents = componentsSeparatedByString(";").map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
        if headerComponents.count > 1 {
            let parameters = headerComponents[1..<headerComponents.count]
                .map { $0.componentsSeparatedByString("=") }
                .toDictionary { ($0[0], $0[1]) }
            
            // Default according to RFC is ISO-8859-1, but probably nothing obeys that, so default
            // to UTF-8 instead.
            var encoding = NSUTF8StringEncoding
            if let charset = parameters["charset"], let parsedEncoding = charset.encodingForName() {
                encoding = parsedEncoding
            }
            
            return (contentType: headerComponents[0], encoding: encoding)
        } else {
            return (contentType: headerComponents[0], encoding: nil)
        }
    }
    
    /// Returns identifier for the encoding.
    func encodingForName() -> UInt? {
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