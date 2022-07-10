//
//  CollectionViewModel.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import Foundation
import RxSwift
import RxRelay

final class CollectionViewModel {
    var coordinator: CollectionCoordinator?
    
    init(coordinator: CollectionCoordinator) {
        self.coordinator = coordinator
    }
    
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output {
        
        return Output()
    }
    
}
