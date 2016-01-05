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

// Support pattern matching on boolean expressions.
func ~= <T>(pattern: T -> Bool, value: T) -> Bool {
    return pattern(value)
}

// Allows using `hasPrefix("XXX")` as a pattern matching expression. See
// http://oleb.net/blog/2015/09/swift-pattern-matching/.
func hasPrefix(prefix: String)(value: String) -> Bool {
    return value.hasPrefix(prefix)
}

extension String {
    /// Parses this string as an HTTP Content-Type header.
    func parseAsHTTPContentTypeHeader() -> (mimeType: String, encoding: UInt) {
        let headerComponents = componentsSeparatedByString(";")
            .map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
        if headerComponents.count > 1 {
            let parameters = headerComponents[1..<headerComponents.count]
                .filter { $0.containsString("=") }
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
            return (mimeType: headerComponents[0], encoding: NSUTF8StringEncoding)
        }
    }

    /// Returns Cocoa encoding identifier for the encoding name in this string.
    func parseAsStringEncoding() -> UInt? {
        switch lowercaseString {
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
    /// Parses the `Content-Type` header in this response into a `(mimeType: String, encoding: UInt)` tuple.
    func contentTypeAndEncoding() -> (mimeType: String, encoding: UInt) {
        if let contentTypeHeader = allHeaderFields["Content-Type"] as? String {
            return contentTypeHeader.parseAsHTTPContentTypeHeader()
        }
        return (mimeType: "application/octet-stream", encoding: NSUTF8StringEncoding)
    }
}

extension Array {
    /// Converts this array to a dictionary of type `[K: V]`, by calling a transform function to
    /// obtain a key and a value from an array element.
    /// - parameters:
    ///   - transform: A function that will transform an array element of type `Element` into a
    ///                `(K, V)` tuple.
    /// - returns: A dictionary having items of type `K` as keys, and type `V` as values.
    func toDictionary<K, V>(transform: Element -> (K, V)) -> [K: V] {
        var dict: [K: V] = [:]
        for item in self {
            let (key, value) = transform(item)
            dict[key] = value
        }
        return dict
    }
}
