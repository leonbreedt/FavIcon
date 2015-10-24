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
public enum FavIcon {
    /// An icon referenced by a `<link rel="shortcut icon">` element.
    /// - Parameters:
    ///   - url: The URL the icon can be retrieved from.
    case ShortcutIcon(url: NSURL)
    /// A favicon.ico file.
    /// - Parameters:
    ///   - url: The URL the icon can be retrieved from.
    case FavIconICO(url: NSURL)
}

/// Represents an error while attempting to detect icons.
public enum FavIconDetectionError : ErrorType {
    /// The base URL is not valid.
    case InvalidBaseURL
    /// No data for response, or missing response.
    case MissingResponse
    /// Unsupported encoding for response.
    case InvalidResponseEncoding
    /// File was not found (HTTP 404).
    case NotFound
    /// File exists, but is not text.
    case NotPlainText
    /// An HTTP error occurred while attempting to detect icons.
    case HTTPError(response: NSHTTPURLResponse)
}

/// Responsible for detecting all of the different icons supported by a given site.
public class FavIconDetector {
    
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
    public static func detect(url: NSURL, completion: [FavIcon] -> Void) {
        let queue = NSOperationQueue()
        queue.suspended = true
        queue.maxConcurrentOperationCount = 2 // Only 2 concurrent connections to server (be a good citizen).
        
        let baseURLTextOperation = DownloadTextOperation(url: url)
        let icoFileExistsOperation = CheckURLExistsOperation(url: NSURL(string: "/favicon.ico", relativeToURL: url)!.absoluteURL)
        let processResultsOperation = NSBlockOperation {
            var icons: [FavIcon] = []
            
            if let result = baseURLTextOperation.result {
                switch result {
                case .TextDownloaded(let actualURL, let text, let contentType):
                    if contentType == "text/html" {
                        for link in HTMLDocument(string: text).query("/html/head/link") {
                            if let rel = link.attributes["rel"], href = link.attributes["href"], url = NSURL(string: href, relativeToURL: actualURL) {
                                switch rel.lowercaseString {
                                case "shortcut icon":
                                    icons.append(FavIcon.ShortcutIcon(url: url.absoluteURL))
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
                    icons.append(FavIcon.FavIconICO(url: actualURL))
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
    public static func detect(url urlString: String, completion: [FavIcon] -> Void) throws {
        guard let url = NSURL(string: urlString) else { throw FavIconDetectionError.InvalidBaseURL }
        detect(url, completion: completion)
    }

    private init () {
    }
}

public enum URLResult {
    case TextDownloaded(url: NSURL, text: String, contentType: String)
    case Success(url: NSURL)
    case Failed(error: ErrorType)
}

public enum URLRequestError : ErrorType {
    case MissingResponse
    case FileNotFound
    case NotPlainText
    case InvalidTextEncoding
    case HTTPError(response: NSHTTPURLResponse)
}

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
        
        var contentType = "application/octet-stream"
        var encoding: UInt?
        if let contentTypeHeader = response.allHeaderFields["Content-Type"] as? String {
            let (type, enc) = contentTypeHeader.parseAsHTTPContentTypeHeader()
            contentType = type
            encoding = enc
        }
        
        switch contentType {
        case "application/json", hasPrefix("text/"):
            if let text = String(data: data, encoding: encoding ?? NSUTF8StringEncoding) {
                return .TextDownloaded(url: response.URL!, text: text, contentType: contentType)
            }
            return .Failed(error: URLRequestError.InvalidTextEncoding)
        default:
            return .Failed(error: URLRequestError.NotPlainText)
        }
    }
}

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