//
//  Project.swift
//  Widget
//
//  Created by Claude on 2025/01/01.
//

import ProjectDescription

// MARK: - Widget Extension Project Configuration
// ==============================================
// 이 파일은 Widget Extension 프로젝트의 Tuist 설정 예시입니다.
// 실제 사용 시 프로젝트 구조에 맞게 수정이 필요합니다.
//
// 주요 설정:
// - product: .appExtension (Widget Extension은 App Extension 타입)
// - bundleId: 메인 앱 Bundle ID + ".Widget"
// - NSExtensionPointIdentifier: "com.apple.widgetkit-extension"
// - App Groups: 메인 앱과 동일한 App Group ID 사용
// ==============================================

let project = Project(
    name: "ACNHWidget",
    targets: [
        .target(
            name: "ACNHWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "leeari.NookPortalPlus.Widget",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "ACNH Widget",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            entitlements: .dictionary([
                "com.apple.security.application-groups": .array([
                    .string("group.leeari.NookPortalPlus")
                ])
            ]),
            dependencies: []
        )
    ]
)
