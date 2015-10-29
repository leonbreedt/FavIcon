# FavIcon
FavIcon is a tiny Swift library for downloading an icon representing a website’s brand.

Wait, why is a library needed to do this? Surely it's just a simple HTTP GET of `/favicon.ico`, right? Right?
Well. Go have a read of [http://stackoverflow.com/questions/19029342/favicons-best-practices], and see how you feel about programming afterwards.

## Using
Perhaps you have a 16x16 location in your user interface where you want to put the icon of a website the user is currently visiting?

```swift
try FavIcons.downloadPreferred(url: "https://apple.com", width: 16, height: 16) { result in
    switch result {
    case .Success(let image):
        // On iOS, this is a UIImage, do something with it here.
        break
    case .Failure(let error):
        // Ignore if you please!
        break
}
`

This will detect all of the available icons at the URL, and if it is able to determine their sizes, it will try to find the icon closest in size to your desired size, otherwise it will just take the first one it found.

If this is not suitable, you can download them all using `downloadAll(url:completion:)`.

Or perhaps you’d like to take a stab at downloading them yourself at a later time, in which case `detect(url:completion:)` is probably more to your liking.

## Experimenting
The project ships with a playground in which you can try it out for yourself. Just be sure to build the `FavIcon-iOS` target before you try to use the playground, or you will get an import error when it tries to import the FavIcon framework.

## License
Apache 2.0
