// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [
            "Alamofire": .framework, // default is .staticFramework
            /// 아래 에러 해결을 위해 Rx와 관련된 라이브러리를 dynamicFrameWork로 설정.
            /// error: failed to demangle superclass of DelegateProxy from mangled name 'So16_RXDelegateProxyC': 
            "RxSwift" : .framework,
            "RxCocoa": .framework,
            "RxDataSources": .framework,
            "ReactorKit": .framework,
            "RxCocoaRuntime" : .framework,
            "RxRelay" : .framework
        ],
        baseSettings: .settings(
            base: [
                "EXCLUDED_ARCHS[sdk=iphonesimulator*]": "arm64"
            ]
        )
    )
#endif

let package = Package(
    name: "ACNH-wiki",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMinor(from: "5.10.0")),
        .package(url: "https://github.com/ReactorKit/ReactorKit.git", .upToNextMinor(from: "3.2.0")),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMinor(from: "7.10.2")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMinor(from: "6.8.0")),
        .package(url: "https://github.com/RxSwiftCommunity/RxDataSources.git", .upToNextMinor(from: "5.0.0")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMinor(from: "12.7.0"))
    ]
)
