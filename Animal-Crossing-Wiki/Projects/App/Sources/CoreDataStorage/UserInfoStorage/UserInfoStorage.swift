//
//  UserInfoStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

protocol UserInfoStorage {
    func fetchUserInfo() -> UserInfo?
    func updateUserInfo(_ userInfo: UserInfo)
    func resetUserInfo()
}
