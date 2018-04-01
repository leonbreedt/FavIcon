# FavIcon [![License](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](https://raw.githubusercontent.com/leonbreedt/FavIcon/master/LICENSE) [![Build Status](https://travis-ci.org/leonbreedt/FavIcon.svg)](https://travis-ci.org/leonbreedt/FavIcon) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![Swift 4.0](https://img.shields.io/badge/Swift-4.0-orange.svg) ![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20-lightgrey.svg)
FavIcon is a tiny Swift library for downloading the favicon representing a website.

Wait, why is a library needed to do this? Surely it's just a simple HTTP GET of
`/favicon.ico`, right? Right?  Well. Go have a read of [this StackOverflow
post](http://stackoverflow.com/questions/19029342/favicons-best-practices), and
see how you feel afterwards.

## Quick Start

### CocoaPods

*Note:* CocoaPods (1.4.0 or later) is required.

Add it to your `Podfile`:

```ruby
use_frameworks!
pod 'FavIcon', '~> 3.0.0'
```

### Carthage

Add it to your `Cartfile`:

```ogdl
github "leonbreedt/FavIcon" ~> 3.0.0
```

## Features
- Detection of `/favicon.ico` if it exists
- Parsing of the HTML at a URL, and scanning for appropriate `<link>` or
  `<meta>` tags that refer to icons using Apple, Google or Microsoft
  conventions.
- Discovery of and parsing of Web Application manifest JSON files to obtain
  lists of icons.
- Discovery of and parsing of Microsoft browser configuration XML files for
  obtaining lists of icons.

Yup. These are all potential ways of indicating that your website has an icon
that can be used in user interfaces. Good work, fellow programmers. 👍

## Usage Example
Perhaps you have a location in your user interface where you want to put
the icon of a website the user is currently visiting?

```swift
try FavIcon.downloadPreferred("https://apple.com") { result in
    if case let .success(image) = result {
      // On iOS, this is a UIImage, do something with it here.
      // This closure will be executed on the main queue, so it's safe to touch
      // the UI here.
    }
}
```

This will detect all of the available icons at the URL, and if it is able to
determine their sizes, it will try to find the icon closest in size to your
desired size, otherwise, it will prefer the largest icon. If it has no idea of
the size of any of the icons, it will prefer the first one it found.

Of course, if this approach is too opaque for you, you can download them all
using `downloadAll(url:completion:)`.

Or perhaps you’d like to take a stab at downloading them yourself at a later
time, choosing which icon you prefer based on your own criteria, in which case
`scan(url:completion:)` will give you information about the detected icons, which
you can feed to `download(url:completion:)` for downloading at your convenience.


## Example Project

See the iOS project in `Example/` for a simple example of how to use the library.

## License

Apache 2.0

