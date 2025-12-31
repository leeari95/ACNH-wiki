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
/// 새로운 이미지를 추가할 때 이 열거형에 케이스를 추가하면 컴파일 타임에 오타를 방지할 수 있습니다.
///
/// Tuist resourceSynthesizers를 사용하면 이 열거형을 자동 생성된 코드로 대체할 수 있습니다.
/// 자세한 내용은 UIColor+extension.swift의 AssetColor 문서를 참조하세요.
enum AssetImage: String, CaseIterable {
    // MARK: - Icons
    case appIcon = "App-Icon"
    case bookDiveIcon = "book-dive-icon"
    case bookFishIcon = "book-fish-icon"
    case bookInsectIcon = "book-insect-icon"

    // MARK: - Fruits
    case apple = "Apple"
    case cherry = "Cherry"
    case coconut = "Coconut"
    case orange = "Orange"
    case peach = "Peach"
    case pear = "Pear"

    /// Asset Catalog에서 해당 이미지를 로드합니다.
    var image: UIImage? {
        UIImage(named: rawValue)
    }

    /// 디버그 빌드에서 이미지 리소스 유효성을 검증합니다.
    static func validateAllImages() {
        #if DEBUG
        for image in Self.allCases {
            if UIImage(named: image.rawValue) == nil {
                assertionFailure("[AssetImage] Missing image resource: \(image.rawValue)")
            }
        }
        #endif
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resizedImage(Size sizeImage: CGSize) -> UIImage? {
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: sizeImage.width, height: sizeImage.height))
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        self.draw(in: frame)
        let resizedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.withRenderingMode(.alwaysOriginal)
        return resizedImage
    }

    static func downloadImage(urlString: String) -> Observable<UIImage?> {
        return Observable.create { observable in
            if let url = URL(string: urlString) {
                ImageCache.default.retrieveImage(forKey: urlString) { result in
                    if let image = try? result.get().image {
                        observable.onNext(image)
                    } else {
                        KingfisherManager.shared.retrieveImage(with: url) { result in
                            observable.onNext(try? result.get().image)
                        }
                    }
                    observable.onCompleted()
                }
            } else {
                observable.onNext(nil)
                observable.onCompleted()
            }
            return Disposables.create()
        }
    }
}
