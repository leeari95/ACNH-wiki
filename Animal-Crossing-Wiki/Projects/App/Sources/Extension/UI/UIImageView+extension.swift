//
//  UIImageView+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/27.
//

import Kingfisher
import UIKit
import OSLog

extension UIImageView {

    convenience init(path: String) {
        self.init(frame: .zero)
        setImage(with: path)
        contentMode = .scaleAspectFit
    }

    func setImage(with urlString: String, options: KingfisherOptionsInfo? = nil) {
        self.kf.setImage(with: URL(string: urlString), options: options) { result in
            switch result {
            case .success: break
            case .failure(let error):
                os_log(.debug, log: .default, "⛔️ 캐시에서 이미지를 가져오는데 실패였습니다.\n에러내용: \(error.localizedDescription)")
            }
        }
    }
}
