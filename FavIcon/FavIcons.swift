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
import LibXML2

#if os(iOS)
    import UIKit
    /// Alias for the iOS image type (`UIImage`).
    public typealias ImageType = UIImage
#elseif os(OSX)
    import Cocoa
    /// Alias for the OS X image type (`NSImage`).
    public typealias ImageType = NSImage
#endif

/// Represents the result of attempting to download an icon.
public enum IconDownloadResult {
    /// Download successful.
    ///
    /// - Parameters:
    ///   - image: The `ImageType` for the downloaded icon.
    case Success(image: ImageType)
    /// Download failed for some reason.
    ///
    /// - Parameters:
    ///   - error: The error which can be consulted to determine the root cause.
    case Failure(error: ErrorType)
}

/// Responsible for detecting all of the different icons supported by a given site.
public class FavIcons {
    /// Scans a base URL, attempting to determine all of the supported icons that can
    /// be used for favicon purposes.
    ///
    /// It will do the following to determine possible icons that can be used:
    ///
    /// - Check whether or not `/favicon.ico` exists.
    /// - If the base URL returns an HTML page, parse the `<head>` section and check for `<link>`
    ///   and `<meta>` tags that reference icons using Apple, Microsoft and Google
    ///   conventions.
    /// - If _Web Application Manifest JSON_ (`manifest.json`) files are referenced, or
    ///   _Microsoft browser configuration XML_ (`browserconfig.xml`) files
    ///   are referenced, download and parse them to check if they reference icons.
    ///
    ///  All of this work is performed in a background queue.
    ///
    /// - Parameters:
    ///   - url: The base URL to scan.
    ///   - completion: A callback to invoke when the scan has completed. The callback will be invoked
    ///                 from a background queue.
    public static func scan(url: NSURL, completion: [DetectedIcon] -> Void) {
        let detectionOperations = [
            DownloadTextOperation(url: url),
            CheckURLExistsOperation(url: NSURL(string: "/favicon.ico", relativeToURL: url)!.absoluteURL),
            CheckURLExistsOperation(url: NSURL(string: "/browserconfig.xml", relativeToURL: url)!.absoluteURL)
        ]
        
        executeURLOperations(detectionOperations) { detectionResults in
            var icons: [DetectedIcon] = []
            var additionalDownloads: [(URLRequestOperation, URLResult -> Void)] = []
            
            switch detectionResults[0] {
            case .TextDownloaded(let actualURL, let text, let contentType):
                if contentType == "text/html" {
                    let document = HTMLDocument(string: text)
                    
                    // 1. Extract any icons referenced by <link> or other elements from the HTML.
                    icons.appendContentsOf(extractHTMLHeadIcons(document, baseURL: actualURL))
                    
                    // Check for Web App Manifest, if present, additional download and processing to do.
                    for link in document.query("/html/head/link") {
                        if let rel = link.attributes["rel"]?.lowercaseString where rel == "manifest",
                           let href = link.attributes["href"],
                           let manifestURL = NSURL(string: href, relativeToURL: url)
                        {
                            additionalDownloads.append((DownloadTextOperation(url: manifestURL), { manifestResult in
                                switch manifestResult {
                                case .TextDownloaded( _, let manifestJSON, _):
                                    icons.appendContentsOf(extractManifestJSONIcons(manifestJSON, baseURL: actualURL))
                                    break
                                default:
                                    break
                                }
                            }))
                        }
                    }
                    
                    // Check for Microsoft browser configuration XML, if present, additional download and processing to do.
                    var browserConfigURL: NSURL? = detectionOperations[2].urlRequest.URL
                    switch detectionResults[2] {
                    case .Success(let actualURL):
                        browserConfigURL = actualURL
                        break
                    default:
                        browserConfigURL = nil
                    }
                    for meta in document.query("/html/head/meta") {
                        if let name = meta.attributes["name"]?.lowercaseString where name == "msapplication-config",
                           let content = meta.attributes["content"]
                        {
                            if content.lowercaseString == "none" {
                                // Explicitly asked us not to download the file.
                                browserConfigURL = nil
                            } else {
                                browserConfigURL = NSURL(string: content, relativeToURL: url)?.absoluteURL
                            }
                        }
                    }
                    if let browserConfigURL = browserConfigURL {
                        additionalDownloads.append((DownloadTextOperation(url: browserConfigURL), { browserConfigResult in
                            switch browserConfigResult {
                            case .TextDownloaded( _, let browserConfigXML, _):
                                let document = XMLDocument(string: browserConfigXML)
                                icons.appendContentsOf(extractBrowserConfigXMLIcons(document, baseURL: actualURL))
                                break
                            default:
                                break
                            }
                        }))
                    }
                }
                break
            default: break
            }
            
            switch detectionResults[1] {
            case .Success(let actualURL):
                icons.append(DetectedIcon(url: actualURL, type: .Classic))
                break
            default: break
            }
            
            if additionalDownloads.count > 0 {
                let additionalOperations = additionalDownloads.map { $0.0 }
                let additionalCompletions = additionalDownloads.map { $0.1 }
                
                executeURLOperations(additionalOperations) { additionalResults in
                    for (index, result) in additionalResults.enumerate() {
                        additionalCompletions[index](result)
                    }
                    
                    completion(icons)
                }
            } else {
                completion(icons)
            }
        }
    }

    /// Downloads an array of detected icons in the background.
    /// - Parameters:
    ///   - icons: The icons to download.
    ///   - completion: A callback to invoke when all download tasks have results available (successful or otherwise).
    ///                 The callback will be invoked from a background queue.
    public static func download(icons: [DetectedIcon], completion: [IconDownloadResult] -> Void) {
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

    /// Downloads all available icons by calling `scan()` to discover the available icons, and then
    /// performing background downloads of each icon.
    ///
    /// - Parameters:
    ///   - url: The URL to scan for icons.
    ///   - completion: A callback to invoke when all download tasks have results available (successful or otherwise).
    ///                 The callback will be invoked from a background queue.
    public static func downloadAll(url: NSURL, completion: [IconDownloadResult] -> Void) {
        scan(url) { icons in
            download(icons, completion: completion)
        }
    }
    
    /// Downloads the most preferred icon, by calling `scan()` to discover available icons, and then choosing
    /// the icon that is closest to a preferred width and height to download.
    ///
    /// - Parameters:
    ///   - url: The URL to scan for icons.
    ///   - width: The preferred icon width, in pixels.
    ///   - height: The preferred icon height, in pixels.
    ///   - completion: A callback to invoke when the download task has produced a result. The callback will
    ///                 be invoked from a background queue.
    ///
    /// - Note: If the site has no icons with explicitly declared dimensions, the first icon found will be downloaded. It will
    ///         NOT download each icon to determine its dimensions.
    public static func downloadPreferred(url: NSURL, width: Int, height: Int, completion: IconDownloadResult -> Void) throws {
        scan(url) { icons in
            if icons.count == 0 {
                completion(IconDownloadResult.Failure(error: IconError.NoIconsDetected))
                return
            }
            
            let rankedIcons = icons.sort { a, b in
                if let sizeA = a.dimensions, let sizeB = b.dimensions {
                    let isWidthACloser = abs(width - sizeA.width) < abs(width - sizeB.width)
                    let isHeightACloser = abs(height - sizeA.height) < abs(height - sizeB.height)
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
                    case .Classic: return true
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
    private static func executeURLOperations(operations: [URLRequestOperation], concurrency: Int = 2, queue: NSOperationQueue? = nil, completion: [URLResult] -> Void) {
        guard operations.count > 0 else {
            completion([])
            return
        }
        
        let queue = queue ?? NSOperationQueue()
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
    
    /// Extracts a list of icons from a Web Application Manifest file
    ///
    /// - Parameters:
    ///   - jsonString: A JSON string containing the contents of the manifest file.
    ///   - baseURL: A base URL to combine with any relative image paths.
    static func extractManifestJSONIcons(jsonString: String, baseURL: NSURL) -> [DetectedIcon] {
        var icons: [DetectedIcon] = []
        
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
           let jsonObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)),
           let manifest = jsonObject as? NSDictionary,
           let manifestIcons = manifest["icons"] as? [NSDictionary]
        {
            for icon in manifestIcons {
                if let type = icon["type"] as? String where type.lowercaseString == "image/png",
                   let src = icon["src"] as? String, url = NSURL(string: src, relativeToURL: baseURL)?.absoluteURL
                {
                    let sizes = parseHTMLIconSizes(icon["sizes"] as? String)
                    if sizes.count > 0 {
                        for size in sizes {
                            icons.append(DetectedIcon(url: url, type: .WebAppManifest, width: size.width, height: size.height))
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
    /// - Parameters:
    ///   - document: An `XMLDocument` for the Microsoft browser configuration file.
    ///   - baseURL: A base URL to combine with any relative image paths.
    static func extractBrowserConfigXMLIcons(document: XMLDocument, baseURL: NSURL) -> [DetectedIcon] {
        var icons: [DetectedIcon] = []
        
        for tile in document.query("/browserconfig/msapplication/tile/*") {
            if let src = tile.attributes["src"], let url = NSURL(string: src, relativeToURL: baseURL)?.absoluteURL {
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
    
    /// Extracts a list of icons from the `<head>` section of an HTML document.
    ///
    /// - Parameters:
    ///   - document: An HTML document to process.
    ///   - baseURL: A base URL to combine with any relative image paths.
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
                                    icons.append(DetectedIcon(url: url.absoluteURL, type: .Classic, width: size.width, height: size.height))
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
                            icons.append(DetectedIcon(url: url.absoluteURL, type: .Classic))
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
        
        for meta in document.query("/html/head/meta") {
            if let name = meta.attributes["name"]?.lowercaseString, content = meta.attributes["content"], url = NSURL(string: content, relativeToURL: baseURL) {
                switch name {
                case "msapplication-tileimage":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 144, height: 144))
                    break
                case "msapplication-square70x70logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 70, height: 70))
                    break
                case "msapplication-square150x150logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 150, height: 150))
                    break
                case "msapplication-wide310x150logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 310, height: 150))
                    break
                case "msapplication-square310x310logo":
                    icons.append(DetectedIcon(url: url, type: .MicrosoftPinnedSite, width: 310, height: 310))
                    break
                default:
                    break
                }
            }
        }

        return icons
    }
    
    /// Helper function for parsing a W3 `sizes` attribute value.
    ///
    /// - Parameters:
    ///   - string: If not `nil`, the value of the attribute to parse (e.g. `50x50 144x144`).
    /// - Returns: An array of `(width: Int, height: Int)` tuples for each size found.
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
enum IconError : ErrorType {
    /// The base URL specified is not a valid URL.
    case InvalidBaseURL
    /// At least one icon to must be specified for downloading.
    case AtLeastOneOneIconRequired
    /// Unexpected response when downloading
    case InvalidDownloadResponse
    /// No icons were detected, so nothing could be downloaded.
    case NoIconsDetected
}

// MARK: - Extensions

extension FavIcons {
    /// Convenience overload for `scan(_:completion:)` that takes a `String` instead of an `NSURL` as the URL parameter.
    /// Throws an error if the URL is not a valid URL.
    public static func scan(url: String, completion: [DetectedIcon] -> Void) throws {
        guard let url = NSURL(string: url) else { throw IconError.InvalidBaseURL }
        scan(url, completion: completion)
    }

    /// Convenience overload for `downloadAll(_:completion:)` that takes a `String` instead of an `NSURL` as the URL parameter.
    /// Throws an error if the URL is not a valid URL.
    public static func downloadAll(url: String, completion: [IconDownloadResult] -> Void) throws {
        guard let url = NSURL(string: url) else { throw IconError.InvalidBaseURL }
        downloadAll(url, completion: completion)
    }

    /// Convenience overload for `downloadPreferred(_:width:height:completion:)` that takes a `String` instead of an `NSURL` as the URL parameter.
    /// Throws an error if the URL is not a valid URL.
    public static func downloadPreferred(url: String, width: Int, height: Int, completion: IconDownloadResult -> Void) throws {
        guard let url = NSURL(string: url) else { throw IconError.InvalidBaseURL }
        try downloadPreferred(url, width: width, height: height, completion: completion)
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