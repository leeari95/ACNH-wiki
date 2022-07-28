//
//  TurnipResponseDTO.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/05/17.
//

import Foundation

// MARK: - TurnipResponseDTO
struct TurnipResponseDTO: Decodable {
    /// Request와 함께 서버로 전송된 입력들을 포함하는 배열, 최대 12개의 값이 담겨있습니다.
    let filters: [Int]
    /// 해당하는 주의 최소 가격.
    let minWeekValue: Int
    /// 1/2일당 최소 및 최대 가격, 총 12개의 값을 포함하는 배열. 배열의 각 1/2일은 [최소값, 최대값]을 포함합니다.
    let minMaxPattern: [[Int]]
    /// 1/2일당 평균 가격, 총 12개의 값을 포함하는 배열. 일요일은 포함되지 않습니다.
    let avgPattern: [Int]
    /// 무값 그래프 미리보기 사진에 대한 링크입니다.
    let preview: String
}
