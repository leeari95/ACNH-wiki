//
//  Reactor+extension.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/30.
//

import UIKit
import RxSwift
import RxCocoa

public extension Reactive where Base: UIViewController {
    public var viewDidLoad: ControlEvent<Void> {
        public let source = self.methodInvoked(#selector(Base.viewDidLoad)).map { _ in }
        return ControlEvent(events: source)
    }
}
