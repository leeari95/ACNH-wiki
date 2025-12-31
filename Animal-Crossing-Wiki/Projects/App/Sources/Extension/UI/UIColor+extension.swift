//
//  UIColor+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/14.
//

import UIKit

// MARK: - Asset Color Names (Type-Safe Resource Access)
/// Asset Catalog에 정의된 색상 이름을 타입 안전하게 관리하기 위한 열거형입니다.
/// 새로운 색상을 추가할 때 이 열거형에 케이스를 추가하면 컴파일 타임에 오타를 방지할 수 있습니다.
///
/// ## Tuist Resource Synthesizers 활용 방법
/// Tuist의 리소스 합성 기능을 사용하면 이 열거형 대신 자동 생성된 코드를 활용할 수 있습니다.
///
/// ### 1. Project.swift에 resourceSynthesizers 설정
/// ```swift
/// let project = Project(
///     name: "ACNH-wiki",
///     resourceSynthesizers: [
///         .assets()  // Asset Catalog에서 색상, 이미지 등의 접근자 자동 생성
///     ],
///     targets: [...]
/// )
/// ```
///
/// ### 2. 자동 생성된 코드 사용 예시
/// Tuist가 `tuist generate` 실행 시 자동으로 생성하는 코드:
/// ```swift
/// // 자동 생성된 Asset 접근자 사용
/// let backgroundColor = Asset.Colors.acBackground.color
/// let iconImage = Asset.Icons.appIcon.image
/// ```
///
/// ### 3. Bundle 접근자
/// ```swift
/// let bundle = Bundle.module  // 모듈 번들에 안전하게 접근
/// ```
///
/// 참고: https://docs.tuist.io/guides/develop/projects/synthesized-files
enum AssetColor: String, CaseIterable {
    // MARK: - Background Colors
    case acBackground = "ACBackground"
    case acSecondaryBackground = "ACSecondaryBackground"
    case acHeaderBackground = "ACHeaderBackground"
    case launchBackground = "launchBackground"

    // MARK: - Text Colors
    case acText = "ACText"
    case acSecondaryText = "ACSecondaryText"

    // MARK: - Navigation Colors
    case acNavigationBarTint = "ACNavigationBarTint"

    // MARK: - Catalog Colors
    case catalogBar = "catalog-bar"
    case catalogBackground = "catalog-background"
    case catalogSelected = "catalog-selected"
    case catalogText = "catalog-text"

    /// Asset Catalog에서 해당 색상을 로드합니다.
    /// - Parameter fallback: 색상을 찾지 못했을 때 반환할 기본 색상
    /// - Returns: 로드된 UIColor 또는 fallback 색상
    func color(fallback: UIColor = .clear) -> UIColor {
        UIColor(named: rawValue) ?? fallback
    }

    /// 디버그 빌드에서 색상 리소스 유효성을 검증합니다.
    /// 앱 시작 시 호출하여 누락된 색상 리소스를 조기에 발견할 수 있습니다.
    static func validateAllColors() {
        #if DEBUG
        for color in Self.allCases {
            if UIColor(named: color.rawValue) == nil {
                assertionFailure("[AssetColor] Missing color resource: \(color.rawValue)")
            }
        }
        #endif
    }
}

// MARK: - UIColor Extension
extension UIColor {
    // MARK: - Background Colors
    class var acHeaderBackground: UIColor {
        AssetColor.acHeaderBackground.color(fallback: .clear)
    }

    class var acBackground: UIColor {
        AssetColor.acBackground.color(fallback: .clear)
    }

    class var acSecondaryBackground: UIColor {
        AssetColor.acSecondaryBackground.color(fallback: .clear)
    }

    // MARK: - Text Colors
    class var acText: UIColor {
        AssetColor.acText.color(fallback: .label)
    }

    class var acSecondaryText: UIColor {
        AssetColor.acSecondaryText.color(fallback: .systemGray)
    }

    // MARK: - Navigation Colors
    class var acNavigationBarTint: UIColor {
        AssetColor.acNavigationBarTint.color(fallback: .clear)
    }

    // MARK: - Catalog Colors
    class var catalogBar: UIColor {
        AssetColor.catalogBar.color(fallback: .clear)
    }

    class var catalogBackground: UIColor {
        AssetColor.catalogBackground.color(fallback: .clear)
    }

    class var catalogSelected: UIColor {
        AssetColor.catalogSelected.color(fallback: .clear)
    }

    class var acTabBarTint: UIColor {
        AssetColor.catalogText.color(fallback: .label)
    }
}
