//
//  PreferencesSectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/21.
//

import Foundation
import RxSwift
import RxRelay

final class PreferencesViewModel {
    
    private let storage: CoreDataUserInfoStorage
    
    init(storage: CoreDataUserInfoStorage = CoreDataUserInfoStorage()) {
        self.storage = storage
    }

    struct Input {
        let islandNameText: Observable<String?>
        let userNameText: Observable<String?>
        let hemisphereButtonTitle: Observable<Hemisphere?>
        let startingFruitButtonTitle: Observable<Fruit?>
        
    }
    
    struct Output {
        let userInfo: Observable<UserInfo?>
        let errorMessage: Observable<String>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let currentUserInfo = BehaviorRelay<UserInfo?>(value: nil)
        let errorMessage = BehaviorRelay<String>(value: "")
        
        storage.fetchUserInfo().subscribe(onSuccess: { userInfo in
            if let userInfo = userInfo {
                currentUserInfo.accept(userInfo)
            } else {
                currentUserInfo.accept(UserInfo())
            }
            currentUserInfo
                .compactMap { $0 }
                .withUnretained(self)
                .subscribe(onNext: { owner, newUserInfo in
                    owner.storage.updateUserInfo(newUserInfo)
                    Items.shared.updateUserInfo(newUserInfo)
            }).disposed(by: disposeBag)
        }, onFailure: { error in
            errorMessage.accept(error.localizedDescription)
        }).disposed(by: disposeBag)
        
        input.islandNameText
            .compactMap { $0 }
            .filter { $0 != "" }
            .subscribe(onNext: { islandName in
                if var userInfo = currentUserInfo.value {
                    userInfo.updateIslandName(islandName)
                    currentUserInfo.accept(userInfo)
                }
            }).disposed(by: disposeBag)
        
        input.userNameText
            .compactMap { $0 }
            .filter { $0 != "" }
            .subscribe(onNext: { userName in
                if var userInfo = currentUserInfo.value {
                    userInfo.updateName(userName)
                    currentUserInfo.accept(userInfo)
                }
            }).disposed(by: disposeBag)
        
        input.hemisphereButtonTitle
            .compactMap { $0 }
            .subscribe(onNext: { hemisphere in
                if var userInfo = currentUserInfo.value {
                    userInfo.updateHemisphere(hemisphere)
                    currentUserInfo.accept(userInfo)
                }
            }).disposed(by: disposeBag)
        
        input.startingFruitButtonTitle
            .compactMap { $0 }
            .subscribe(onNext: { fruit in
                if var userInfo = currentUserInfo.value {
                    userInfo.updateFruit(fruit)
                    currentUserInfo.accept(userInfo)
                }
            }).disposed(by: disposeBag)
        
        return Output(
            userInfo: currentUserInfo.asObservable(),
            errorMessage: errorMessage.asObservable()
        )
    }
}
