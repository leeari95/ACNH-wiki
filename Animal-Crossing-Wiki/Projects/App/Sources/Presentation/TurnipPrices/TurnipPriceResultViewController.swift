//
//  TurnipPriceResultViewController.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import UIKit
import SwiftUI

final class TurnipPriceResultViewController: UIViewController {

    private let basePrice: Int
    private let pattern: TurnipPricePattern
    private let minPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    private let maxPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]

    private lazy var hostingController: UIHostingController<TurnipPriceResultView> = {
        let view = TurnipPriceResultView(
            basePrice: basePrice,
            pattern: pattern,
            minPrices: minPrices,
            maxPrices: maxPrices
        )
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        return controller
    }()

    init(
        basePrice: Int,
        pattern: TurnipPricePattern,
        minPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]],
        maxPrices: [TurnipPricesReactor.DayOfWeek: [TurnipPricesReactor.Period: Int]]
    ) {
        self.basePrice = basePrice
        self.pattern = pattern
        self.minPrices = minPrices
        self.maxPrices = maxPrices
        super.init(nibName: nil, bundle: nil)

        // Alert 스타일 설정
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    private func setUpViews() {
        view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
