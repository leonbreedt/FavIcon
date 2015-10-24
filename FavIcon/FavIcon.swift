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

/// Enumerates the types of icons supported.
public enum FavIconType {
    /// The classic favicon .ico file.
    case FavIconICO
    /// A more modern favicon-WxH .png file.
    case FavIconPNG
    /// A file in one of the many dimensions supported by Apple, in .png format.
    case Apple
    /// A file in one of the many dimensions supported by Google, in .png format.
    case Google
    /// A file in one of the many dimensions supported by Microsoft, in .png format.
    case Microsoft
}

/// Represents a detected icon.
public struct FavIcon {
    /// The width of the icon, in pixels.
    let width: Int
    /// The height of the icon, in pixels.
    let height: Int
    /// The type of the icon.
    let type: FavIconType
    /// The URL of the icon file.
    let url: NSURL
}

/// Represents an error while attempting to detect icons.
public enum FavIconDetectionError : ErrorType {
    /// The base URL is not valid
    case InvalidBaseURL
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
    public static func detect(url: NSURL, completion: [FavIcon] -> Void) throws {
        // Only 2 concurrent connections to server (HTTP spec).
        
        // (1.1) Parse website
        // (1.2.1) Check for favicon.ico
        // (1.2.2) Check for favicon-*.png
        // (1.3.1) Check for manifest.json, download & parse if present
        // (1.3.2) Check for browserconfig.xml, download & parse if present
        // Emit URLs
        
        completion([])
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
        try detect(url, completion: completion)
    }

    private init () {
    }
}