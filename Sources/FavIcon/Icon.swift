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

@available(*, deprecated, message: "renamed to Icon")
public typealias DetectedIcon = Icon

/// Represents a detected icon.
public struct Icon {
    /// The absolute URL for the icon file.
    public let url: URL
    /// The type of the icon.
    public let type: IconType
    /// The width of the icon, if known, in pixels.
    public let width: Int?
    /// The height of the icon, if known, in pixels.
    public let height: Int?

    init(url: URL, type: IconType, width: Int? = nil, height: Int? = nil) {
        self.url = url
        self.type = type
        self.width = width
        self.height = height
    }
}
