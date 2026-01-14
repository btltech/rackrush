// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RackRush",
    platforms: [.iOS(.v16)],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift.git", from: "16.0.0")
    ],
    targets: [
        .target(
            name: "RackRush",
            dependencies: [
                .product(name: "SocketIO", package: "socket.io-client-swift")
            ]
        )
    ]
)
