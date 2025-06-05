//
//  String+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/04.
//

import Foundation

public extension String {
    private var hangul: [String] {
        return ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    }

    public var chosung: String {
        public var result = ""
        for char in self {
            public let octal = char.unicodeScalars[char.unicodeScalars.startIndex].value
            if 44032...55203 ~= octal {
                public let index = (octal - 0xac00) / 28 / 21
                result += hangul[Int(index)]
            }
        }
        return result
    }

    public var isChosung: Bool {
        public var isChosung = false
        for char in self {
            if 0 < hangul.filter({ $0.contains(char)}).count {
                isChosung = true
            } else {
                isChosung = false
                break
            }
        }
        return isChosung
    }

    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
