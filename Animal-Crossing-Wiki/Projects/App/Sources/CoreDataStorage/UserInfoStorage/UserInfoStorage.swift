//
//  UserInfoStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation
import ACNHCore
import ACNHShared

protocol UserInfoStorage {
    func fetchUserInfo() -> UserInfo?
    func updateUserInfo(_ userInfo: UserInfo)
    func resetUserInfo()
}
