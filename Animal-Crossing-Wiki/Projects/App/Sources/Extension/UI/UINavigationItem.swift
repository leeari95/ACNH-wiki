//
//  UINavigationItem.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/19.
//

import UIKit

extension UINavigationItem {

    func enableMultilineTitle() {
        // 비공개 API 사용 제거
        // setValue(true, forKey: "__largeTitleTwoLineMode")는 앱스토어 거절 위험
        // 다줄 타이틀이 필요한 경우 공개 API 사용 또는 커스텀 뷰 구현 필요
    }

}
