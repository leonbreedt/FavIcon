//: Playground - noun: a place where people can play

import UIKit
import FavIcon
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely()

try FavIcons.downloadAll(url: "https://soundcloud.com") { results in
    for result in results {
        switch result {
        case .Success(let image):
            let icon: UIImage = image
            break
        default:
            break
        }
    }
}
