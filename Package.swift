import PackageDescription

let package = Package(
    name: "FavIcon",
    targets: [
        Target(name: "Clibxml2"),
        Target(name: "FavIcon", dependencies: ["Clibxml2"])
    ]    
)
