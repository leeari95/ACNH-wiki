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
}
