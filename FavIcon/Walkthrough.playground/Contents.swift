//: Welcome to the introduction for the FavIcon library. I hope you find it useful and easy to use.
//: I'll walk you through the various usage scenarios.

import UIKit
import FavIcon
//: First, we need to ensure network requests get a chance to execute.
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
//: Now we're ready. We'll use `downloadPreferred(url:completion:)` first, which tries to download an icon
//: matching your desired with and height. Of course, if the website does not have many icons 
//: to choose from, you may not get the size you desire. But we'll try, at least.
//: 
//: Since downloads happen asynchronously, you need to provide a closure that will get
//: called when the background task is finished.
try FavIcons.downloadPreferred(url: "https://microsoft.com", width: 32, height: 32) { result in
//: The result passed to the closure is a `DownloadResultType`, which is a Swift enum
//: that will either give you a successful result, with an associated `UIImage`, or
//: it will give you a failed result, with an associated `ErrorType`.
    switch result {
    case .Success(let image):
        let icon = image
        break
    case .Failure(let error):
        print("failed - \(error)")
        break
    }
}
//: If you want to download all detected icons, call `downloadAll(url:completion:)`.
try FavIcons.downloadAll(url: "https://microsoft.com") { results in
    let numberOfIcons = results.count
    for (index, result) in results.enumerate() {
        switch result {
        case .Success(let image):
            let icon = image
            break
        case .Failure(let error):
            print("failed \(index) - \(error)")
            break
        }
    }
}
//: If you just want to know which icons are available, you can use the `detect(_:completion:)` method instead.
try FavIcons.detect(url: "https://google.com") { icons in
    for icon in icons {
        let details = "icon: \(icon.url), type \(icon.type), width: \(icon.width), height: \(icon.height)"
    }
}
//: That's it. Good luck, have fun!
