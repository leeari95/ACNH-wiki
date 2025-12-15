//
//  TargetScript+.swift
//  ProjectDescriptionHelpers
//
//  Created by Ari on 11/11/24.
//

import ProjectDescription

public extension TargetScript {
    static let runSwiftLint = TargetScript.pre(
        path: .relativeToRoot("Animal-Crossing-Wiki/Scripts/SwiftLintRunScript.sh"),
        name: "Run Script - SwiftLint"
    )
    
    static let runSwiftLintAutocorrect = TargetScript.pre(
        path: .relativeToRoot("Animal-Crossing-Wiki/Scripts/SwiftLintAutocorrectScript.sh"),
        name: "Run Script - SwiftLint autocorrect"
    )

    static let uploadFirebaseDsym = TargetScript.post(
        path: .relativeToRoot("Animal-Crossing-Wiki/Scripts/FirebaseCrashlyticsScript.sh"),
        name: "Run Script - Firebase dSYM upload",
        inputPaths: [
            .glob(.relativeToManifest("${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}")),
            .glob(.relativeToManifest("Animal-Crossing-Wiki/Projects/App/Resources/GoogleService-Info.plist"))
        ],
        basedOnDependencyAnalysis: false,
        runForInstallBuildsOnly: true
    )
}
