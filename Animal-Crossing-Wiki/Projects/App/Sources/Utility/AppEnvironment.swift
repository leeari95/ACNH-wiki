//
//  AppEnvironment.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2026/06/04.
//

import Foundation

enum AppEnvironment {
    /// 단위 테스트 실행 여부.
    ///
    /// 테스트 스킴(`Project.swift`)이 `IS_UNIT_TESTING=1`을 주입하므로 환경 변수만으로 판정한다.
    /// `NSClassFromString("XCTestCase")` 같은 런타임 probe는 (1) XCTest를 링크하는 향후 UI 테스트에서
    /// 앱이 빈 화면으로 부팅되고, (2) 릴리스 바이너리에 XCTest가 새어 들어갈 경우 크래시 리포팅/애널리틱스가
    /// 조용히 비활성화될 수 있어 사용하지 않는다.
    static var isUnitTesting: Bool {
        ProcessInfo.processInfo.environment["IS_UNIT_TESTING"] == "1"
    }
}
