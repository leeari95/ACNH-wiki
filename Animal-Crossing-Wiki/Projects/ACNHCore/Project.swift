import ProjectDescription

let project = Project(
    name: "ACNHCore",
    targets: [
        .target(
            name: "ACNHCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "leeari.ACNHCore",
            deploymentTargets: .iOS("16.0"),
            sources: ["Sources/**"],
            dependencies: []
        ),
        .target(
            name: "ACNHCoreTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "leeari.ACNHCoreTests",
            deploymentTargets: .iOS("16.0"),
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "ACNHCore")
            ]
        )
    ]
)