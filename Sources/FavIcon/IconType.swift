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

@available(*, deprecated, message: "renamed to IconType")
public typealias DetectedIconType = IconType

/// Enumerates the types of detected icons.
public enum IconType: UInt {
    /// A shortcut icon.
    case shortcut
    /// A classic icon (usually in the range 16x16 to 48x48).
    case classic
    /// A Google TV icon.
    case googleTV
    /// An icon used by Chrome/Android.
    case googleAndroidChrome
    /// An icon used by Safari on OS X for tabs.
    case appleOSXSafariTab
    /// An icon used iOS for Web Clips on home screen.
    case appleIOSWebClip
    /// An icon used for a pinned site in Windows.
    case microsoftPinnedSite
    /// An icon defined in a Web Application Manifest JSON file, mainly Android/Chrome.
    case webAppManifest
    /// An icon defined by the og:image meta property.
    case openGraphImage
}


