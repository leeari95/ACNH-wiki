//
//  UserInfoSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/21.
//

import Foundation
import RxSwift
import RxRelay

final class UserInfoSectionViewModel {
    
    private let storage: CoreDataUserInfoStorage = CoreDataUserInfoStorage()

    struct Output {
        let userInfo: Observable<UserInfo?>
    }
    
    func transform(disposeBag: DisposeBag) -> Output {
        let newUserInfo = BehaviorRelay<UserInfo?>(value: nil)

        Items.shared.userInfo
            .subscribe(onNext: { userInfo in
                newUserInfo.accept(userInfo)
            }).disposed(by: disposeBag)

        return Output(
            userInfo: newUserInfo.asObservable()
        )
    }
    
}
