import ProjectDescription

let project = Project(
    name: "ACNHShared",
    targets: [
        .target(
            name: "ACNHShared",
            destinations: .iOS,
            product: .framework,
            bundleId: "leeari.ACNHShared",
            deploymentTargets: .iOS("16.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "ACNHCore", path: "../ACNHCore")
            ]
        ),
        .target(
            name: "ACNHSharedTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "leeari.ACNHSharedTests",
            deploymentTargets: .iOS("16.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "ACNHShared")
            ]
        )
    ]
)