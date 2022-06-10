//
//  UserInfoStorage.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import Foundation

protocol UserInfoStorage {
    func fetchUserInfo(completion: @escaping (Result<UserInfo, Error>) -> Void)
    func updateUserInfo(_ userInfo: UserInfo, completion: @escaping (Result<UserInfo, Error>) -> Void)
    func resetUserInfo()
}
