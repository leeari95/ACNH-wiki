import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Widget Extension Target Configuration (TODO)
// =====================================================
// Widget Extension을 추가하려면 아래 설정을 참고하세요.
//
// 1. App Group 설정 (Apple Developer Portal에서)
//    - App Groups capability 추가
//    - Group ID: "group.leeari.NookPortalPlus"
//    - 메인 앱과 위젯 모두에 동일한 App Group 추가
//
// 2. Widget Extension Target 추가:
//
// let widgetTarget: Target = .target(
//     name: "ACNHWidget",
//     destinations: .iOS,
//     product: .appExtension,
//     bundleId: "leeari.NookPortalPlus.Widget",
//     deploymentTargets: .iOS("16.0"),
//     infoPlist: .extendingDefault(with: [
//         "CFBundleDisplayName": "ACNH Widget",
//         "NSExtension": [
//             "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
//         ]
//     ]),
//     sources: [
//         .glob("../Widget/Sources/**")
//     ],
//     resources: [
//         .glob(pattern: "../Widget/Resources/**")
//     ],
//     entitlements: .dictionary([
//         "com.apple.security.application-groups": .array([
//             .string("group.leeari.NookPortalPlus")
//         ])
//     ]),
//     dependencies: []
// )
//
// 3. 메인 앱 타겟에 Widget Extension 의존성 추가:
//    dependencies: dependencies + [.target(name: "ACNHWidget")]
//
// 4. 메인 앱 타겟에 App Group Entitlement 추가:
//    entitlements: .dictionary([
//        "com.apple.security.application-groups": .array([
//            .string("group.leeari.NookPortalPlus")
//        ])
//    ])
//
// 5. targets 배열에 widgetTarget 추가:
//    targets: [앱타겟, widgetTarget]
//
// 6. SharedDataManager를 메인 앱과 Widget 모두에서 공유하려면:
//    - SharedDataManager.swift를 Shared 모듈로 분리하거나
//    - 메인 앱의 Sources에 복사본을 추가
//    - 데이터 변경 시 WidgetCenter.shared.reloadAllTimelines() 호출
//
// 위젯 코드는 Projects/Widget/ 디렉토리에 있습니다:
// - Sources/ACNHWidgetBundle.swift: 위젯 번들 엔트리 포인트
// - Sources/SharedDataManager.swift: App Group 데이터 공유 매니저
// - Sources/DailyTaskWidget/: 일일 할일 위젯
// - Sources/CollectionProgressWidget/: 수집 진행률 위젯
// =====================================================

let dependencies: [TargetDependency] = [
    .SPM.Kingfisher,
    .SPM.Alamofire,
    .SPM.ReactorKit,
    .SPM.RxDataSources,
    .SPM.FirebaseAnalytics,
    .SPM.FirebaseCrashlytics
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
        testAction: nil,
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
        )
    ],
    schemes: schemes,
    additionalFiles: [
        .glob(pattern: .relativeToRoot("Animal-Crossing-Wiki/Configurations/Base.xcconfig")),
        .glob(pattern: .relativeToRoot("Animal-Crossing-Wiki/Configurations/TargetVersion.xcconfig"))
    ],
)
