import ProjectDescription
import ProjectDescriptionHelpers

let dependencies: [TargetDependency] = [
    .SPM.Kingfisher,
    .SPM.Alamofire,
    .SPM.ReactorKit,
    .SPM.RxDataSources
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
    base: [:]
)

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
            scripts: [.runSwiftLintAutocorrect, .runSwiftLint],
            dependencies: dependencies,
            settings: settings,
            coreDataModels: [
                CoreDataModel.coreDataModel("Sources/CoreDataStorage/CoreDataStorage.xcdatamodeld")
            ]
        )
    ]
)
