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
    private var coordinator: DashboardCoordinator?
    
    init(storage: CoreDataUserInfoStorage = CoreDataUserInfoStorage(), coordinator: DashboardCoordinator) {
        self.storage = storage
        self.coordinator = coordinator
    }

    struct Input {
        let islandNameText: Observable<String?>
        let userNameText: Observable<String?>
        let hemisphereButtonTitle: Observable<Hemisphere?>
        let startingFruitButtonTitle: Observable<Fruit?>
        let didTapCancel: Observable<Void>
        let didTapHemisphere: Observable<Void>
        let didTapFruit: Observable<Void>
    }
    
    struct Output {
        let userInfo: Observable<UserInfo?>
        let errorMessage: Observable<String>
        let didChangeHemisphere: Observable<String?>
        let didChangeFruit: Observable<String?>
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        let currentUserInfo = BehaviorRelay<UserInfo?>(value: nil)
        let errorMessage = BehaviorRelay<String>(value: "")
        let currentHemisphere = BehaviorRelay<String?>(value: currentUserInfo.value?.hemisphere.rawValue)
        let currentFruit = BehaviorRelay<String?>(value: currentUserInfo.value?.islandFruit.imageName)
        
        storage.fetchUserInfo().subscribe(onSuccess: { userInfo in
            currentUserInfo.accept(userInfo)
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
                var userInfo = currentUserInfo.value
                userInfo?.updateIslandName(islandName)
                currentUserInfo.accept(userInfo)
            }).disposed(by: disposeBag)
        
        input.userNameText
            .compactMap { $0 }
            .filter { $0 != "" }
            .subscribe(onNext: { userName in
                var userInfo = currentUserInfo.value
                userInfo?.updateName(userName)
                currentUserInfo.accept(userInfo)
            }).disposed(by: disposeBag)
        
        input.hemisphereButtonTitle
            .compactMap { $0 }
            .subscribe(onNext: { hemisphere in
                var userInfo = currentUserInfo.value
                userInfo?.updateHemisphere(hemisphere)
                currentUserInfo.accept(userInfo)
            }).disposed(by: disposeBag)
        
        input.startingFruitButtonTitle
            .compactMap { $0 }
            .subscribe(onNext: { fruit in
                var userInfo = currentUserInfo.value
                userInfo?.updateFruit(fruit)
                currentUserInfo.accept(userInfo)
            }).disposed(by: disposeBag)
        
        input.didTapCancel
            .subscribe(onNext: { _ in
                self.coordinator?.transition(for: .dismiss)
            }).disposed(by: disposeBag)
        
        input.didTapHemisphere
            .subscribe(onNext: { _ in
                self.coordinator?.rootViewController.visibleViewController?
                    .showSelectedItemAlert(
                        Hemisphere.allCases.map { $0.rawValue.localized },
                        currentItem: currentUserInfo.value?.hemisphere.rawValue.localized ?? ""
                    ).compactMap { Hemisphere.title($0) }
                    .subscribe(onNext: { title in
                        currentHemisphere.accept(title)
                    }).disposed(by: disposeBag)
            }).disposed(by: disposeBag)
        
        input.didTapFruit
            .subscribe(onNext: { _ in
                self.coordinator?.rootViewController.visibleViewController?
                    .showSelectedItemAlert(
                        Fruit.allCases.map { $0.imageName.localized },
                        currentItem: currentUserInfo.value?.islandFruit.imageName.localized ?? ""
                    ).compactMap { Fruit.title($0) }
                    .subscribe(onNext: { title in
                        currentFruit.accept(title)
                    }).disposed(by: disposeBag)
            }).disposed(by: disposeBag)
        
        return Output(
            userInfo: currentUserInfo.asObservable(),
            errorMessage: errorMessage.asObservable(),
            didChangeHemisphere: currentHemisphere.asObservable(),
            didChangeFruit: currentFruit.asObservable()
        )
    }
}
