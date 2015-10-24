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

class FavIcon {
    
    private init () {
    }
    
    func load(url: NSURL) -> ImageType {
        return ImageType()
    }
}