//
//  UIImage+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/23.
//

import UIKit
import Kingfisher
import RxSwift

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
                        let resource = ImageResource(downloadURL: url, cacheKey: urlString)
                        KingfisherManager.shared.retrieveImage(with: resource) { result in
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
