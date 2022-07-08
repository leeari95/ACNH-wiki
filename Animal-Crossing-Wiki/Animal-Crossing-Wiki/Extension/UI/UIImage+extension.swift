//
//  UIImage+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/23.
//

import UIKit

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
}
