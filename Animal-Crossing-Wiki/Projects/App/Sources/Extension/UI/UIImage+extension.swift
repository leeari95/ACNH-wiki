//
//  UIImage+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/23.
//

import UIKit
import Kingfisher
import RxSwift

// MARK: - Asset Image Names (Type-Safe Resource Access)
/// Asset Catalog에 정의된 이미지 이름을 타입 안전하게 관리하기 위한 열거형입니다.
///
/// ## 현재 상태
/// 이 열거형은 Tuist resourceSynthesizers로의 마이그레이션을 위한 **레퍼런스 구현**입니다.
/// 프로젝트의 이미지 리소스가 동적으로 결정되는 경우가 많아(예: `Fruit.imageName`, `Category.iconName`),
/// 모든 이미지를 이 열거형으로 관리하는 것은 현실적이지 않습니다.
///
/// ## 권장 마이그레이션 방법
/// Tuist resourceSynthesizers를 사용하면 이 열거형을 자동 생성된 코드로 대체할 수 있습니다.
/// 자세한 내용은 UIColor+extension.swift의 AssetColor 문서를 참조하세요.
///
/// ## 사용 예시
/// ```swift
/// // 정적으로 알려진 이미지에 대해 타입 안전한 접근
/// let icon = AssetImage.appIcon.image
///
/// // 동적으로 결정되는 이미지는 기존 방식 유지
/// let fruitImage = UIImage(named: fruit.imageName)
/// ```
enum AssetImage: String, CaseIterable {
    // MARK: - App Icons
    case appIcon = "App-Icon"

    // MARK: - Book Icons
    case bookDiveIcon = "book-dive-icon"
    case bookFishIcon = "book-fish-icon"
    case bookInsectIcon = "book-insect-icon"

    /// Asset Catalog에서 해당 이미지를 로드합니다.
    var image: UIImage? {
        UIImage(named: rawValue)
    }
}

// MARK: - UIImage Extension
extension UIImage {
    /// 이미지를 지정된 크기로 리사이즈합니다.
    /// 원본 이미지의 scale을 유지하여 Retina 디스플레이에서도 선명하게 표시됩니다.
    /// - Parameter sizeImage: 리사이즈할 목표 크기
    /// - Returns: 리사이즈된 UIImage
    /// - Note: Swift API Guidelines에 따르면 파라미터 레이블은 소문자로 시작해야 하지만,
    ///         기존 호출부와의 호환성을 위해 'Size' 레이블을 유지합니다.
    func resizedImage(Size sizeImage: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: sizeImage, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: sizeImage))
        }
    }

    /// URL에서 이미지를 비동기로 다운로드합니다.
    /// Kingfisher가 내부적으로 캐시를 먼저 확인하고, 없으면 네트워크에서 다운로드합니다.
    /// - Parameter urlString: 이미지 URL 문자열
    /// - Returns: 다운로드된 UIImage를 방출하는 Observable (메인 스레드에서 방출)
    /// - Note: 다운로드 실패 시 nil을 방출하며, 디버그 빌드에서는 에러를 로깅합니다.
    static func downloadImage(urlString: String) -> Observable<UIImage?> {
        return Observable.create { observer in
            guard let url = URL(string: urlString) else {
                #if DEBUG
                print("[UIImage.downloadImage] Invalid URL: \(urlString)")
                #endif
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }

            // Kingfisher의 retrieveImage는 캐시를 먼저 확인하고 없으면 네트워크에서 다운로드
            // callbackQueue를 .mainAsync로 설정하여 메인 스레드에서 콜백 실행
            let options: KingfisherOptionsInfo = [.callbackQueue(.mainAsync)]
            let task = KingfisherManager.shared.retrieveImage(with: url, options: options) { result in
                switch result {
                case .success(let value):
                    observer.onNext(value.image)
                case .failure(let error):
                    #if DEBUG
                    print("[UIImage.downloadImage] Failed to load image from \(urlString): \(error.localizedDescription)")
                    #endif
                    observer.onNext(nil)
                }
                observer.onCompleted()
            }

            return Disposables.create {
                task?.cancel()
            }
        }
    }
}
