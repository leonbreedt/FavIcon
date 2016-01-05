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

/// Enumerates the types of detected icons.
public enum DetectedIconType: UInt {
    /// A shortcut icon.
    case Shortcut
    /// A classic icon (usually in the range 16x16 to 48x48).
    case Classic
    /// A Google TV icon.
    case GoogleTV
    /// An icon used by Chrome/Android.
    case GoogleAndroidChrome
    /// An icon used by Safari on OS X for tabs.
    case AppleOSXSafariTab
    /// An icon used iOS for Web Clips on home screen.
    case AppleIOSWebClip
    /// An icon used for a pinned site in Windows.
    case MicrosoftPinnedSite
    /// An icon defined in a Web Application Manifest JSON file, mainly Android/Chrome.
    case WebAppManifest
}

/// Represents a detected icon.
public struct DetectedIcon {
    /// The absolute URL for the icon file.
    public let url: NSURL
    /// The type of the icon.
    public let type: DetectedIconType
    /// The width of the icon, if known, in pixels.
    public let width: Int?
    /// The height of the icon, if known, in pixels.
    public let height: Int?

    init(url: NSURL, type: DetectedIconType, width: Int? = nil, height: Int? = nil) {
        self.url = url
        self.type = type
        self.width = width
        self.height = height
    }
}
