import ProjectDescription
import ProjectDescriptionHelpers

let dependencies: [TargetDependency] = [
    .SPM.Kingfisher,
    .SPM.Alamofire,
    .SPM.ReactorKit,
    .SPM.RxDataSources,
    .SPM.FirebaseAnalytics,
    .SPM.FirebaseCrashlytics
]

let testDependencies: [TargetDependency] = [
    .target(name: "ACNH-wiki"),
    .SPM.RxTest,
    .SPM.RxBlocking
]

let appPrivacyInfo: PrivacyManifest = .privacyManifest(
    tracking: false,
    trackingDomains: [],
    collectedDataTypes: [],
    accessedApiTypes: [
        [
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp",
            "NSPrivacyAccessedAPITypeReasons": ["C617.1"]
        ],
        [
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategorySystemBootTime",
            "NSPrivacyAccessedAPITypeReasons": ["35F9.1"]
        ],
        [
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryDiskSpace",
            "NSPrivacyAccessedAPITypeReasons": ["E174.1"]
        ],
        [
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]
        ]
    ]
)

let settings: Settings = .settings(
    configurations: [
        .debug(
            name: "Debug",
            xcconfig: .relativeToRoot("Animal-Crossing-Wiki/Configurations/Debug.xcconfig")
        ),
        .release(
            name: "Release",
            xcconfig: .relativeToRoot("Animal-Crossing-Wiki/Configurations/Release.xcconfig")
        )
    ],
    defaultSettings: .recommended
)

let schemes: [Scheme] = [
    .scheme(
        name: "ACNH-wiki",
        shared: true,
        buildAction: .buildAction(targets: ["ACNH-wiki"]),
        testAction: TestAction.targets(["ACNH-wikiTests"]),
        runAction: .runAction(
            configuration: .debug,
            executable: "ACNH-wiki",
            arguments: .arguments(
                environmentVariables: [:],
                launchArguments: [
                    .launchArgument(name: "-FIRDebugDisabled", isEnabled: false),
                    .launchArgument(name: "-FIRDebugEnabled", isEnabled: true)
                ]
            )
        ),
        archiveAction: .archiveAction(configuration: .release, revealArchiveInOrganizer: true),
        profileAction: .profileAction(configuration: .debug, executable: "ACNH-wiki"),
        analyzeAction: .analyzeAction(configuration: .debug)
    )
]

let project = Project(
    name: "ACNH-wiki",
    targets: [
        .target(
            name: "ACNH-wiki",
            destinations: .iOS,
            product: .app,
            bundleId: "leeari.NookPortalPlus",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Info.plist"),
            sources: ["Sources/**"],
            resources:  .resources([
                "Resources/**",
                "Sources/**/*.xib"
            ],
                                   privacyManifest: appPrivacyInfo),
            scripts: [.runSwiftLintAutocorrect, .runSwiftLint, .uploadFirebaseDsym],
            dependencies: dependencies,
            settings: settings,
            coreDataModels: [
                CoreDataModel.coreDataModel("Sources/CoreDataStorage/CoreDataStorage.xcdatamodeld")
            ]
        ),
        .target(
            name: "ACNH-wikiTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "leeari.NookPortalPlus.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: testDependencies
        )
    ],
    schemes: schemes,
    additionalFiles: [
        .glob(pattern: .relativeToRoot("Animal-Crossing-Wiki/Configurations/Base.xcconfig")),
        .glob(pattern: .relativeToRoot("Animal-Crossing-Wiki/Configurations/TargetVersion.xcconfig"))
    ]
)
