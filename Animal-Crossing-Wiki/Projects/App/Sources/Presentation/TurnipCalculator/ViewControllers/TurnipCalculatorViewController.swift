//
//  TurnipCalculatorViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/10.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class TurnipCalculatorViewController: UIViewController, View {

    typealias Reactor = TurnipCalculatorReactor

    var disposeBag = DisposeBag()

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        return stackView
    }()

    private lazy var summaryView = TurnipSummaryView()

    private lazy var buyPriceTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.placeholder = "Enter purchase price".localized
        textField.textAlignment = .center
        textField.font = .preferredFont(for: .title3, weight: .semibold)
        textField.backgroundColor = .acSecondaryBackground
        return textField
    }()

    private lazy var priceTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(TurnipPriceInputCell.self, forCellReuseIdentifier: TurnipPriceInputCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .acBackground
        tableView.isScrollEnabled = false
        tableView.rowHeight = 52
        return tableView
    }()

    private lazy var predictionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear All".localized, for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .preferredFont(for: .body, weight: .medium)
        return button
    }()

    private var priceInputRelay = PublishRelay<(Int, String?)>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpNavigationBar()
    }

    // MARK: - Setup

    private func setUpViews() {
        view.backgroundColor = .acBackground

        view.addSubviews(scrollView)
        scrollView.addSubviews(contentStackView)

        // Summary View
        contentStackView.addArrangedSubview(summaryView)

        // Buy Price Section
        let buyPriceContainer = createSectionContainer(
            title: "Sunday Buy Price".localized,
            content: buyPriceTextField
        )
        contentStackView.addArrangedSubview(buyPriceContainer)

        // Weekly Prices Section
        let priceContainer = createSectionContainer(
            title: "Weekly Prices".localized,
            content: priceTableView
        )
        contentStackView.addArrangedSubview(priceContainer)

        // Prediction Section
        let predictionContainer = createSectionContainer(
            title: "Pattern Predictions".localized,
            content: predictionStackView
        )
        contentStackView.addArrangedSubview(predictionContainer)

        // Clear Button
        contentStackView.addArrangedSubview(clearButton)

        // Add spacing at bottom
        let spacerView = UIView()
        spacerView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        contentStackView.addArrangedSubview(spacerView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            buyPriceTextField.heightAnchor.constraint(equalToConstant: 50),

            priceTableView.heightAnchor.constraint(equalToConstant: CGFloat(12 * 52))
        ])
    }

    private func setUpNavigationBar() {
        navigationItem.title = "Turnip Calculator".localized
        navigationItem.largeTitleDisplayMode = .never

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.tintColor = .acSecondaryText
        navigationItem.rightBarButtonItem = closeButton
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func createSectionContainer(title: String, content: UIView) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(for: .headline, weight: .bold)
        titleLabel.textColor = .acText

        let stack = UIStackView(arrangedSubviews: [titleLabel, content])
        stack.axis = .vertical
        stack.spacing = 12

        container.addSubviews(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Binding

    func bind(reactor: TurnipCalculatorReactor) {
        // Input bindings

        // View did load
        Observable.just(Reactor.Action.viewDidLoad)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Buy price changes
        buyPriceTextField.rx.controlEvent(.editingDidEnd)
            .withLatestFrom(buyPriceTextField.rx.text)
            .map { Reactor.Action.updateBuyPrice($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Price input changes
        priceInputRelay
            .map { Reactor.Action.updatePrice(index: $0.0, price: $0.1) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Clear button
        clearButton.rx.tap
            .map { Reactor.Action.clearAll }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Output bindings

        // Turnip price
        reactor.state.map { $0.turnipPrice }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] turnipPrice in
                self?.updatePriceInputs(turnipPrice: turnipPrice)
            })
            .disposed(by: disposeBag)

        // Summary
        let summaryObservable = reactor.state
            .map { state -> (Int?, Int?) in
                return (state.expectedMinPrice, state.expectedMaxPrice)
            }
            .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }

        summaryObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] min, max in
                self?.summaryView.configure(minPrice: min, maxPrice: max)
            })
            .disposed(by: disposeBag)

        // Predictions
        reactor.state.map { $0.predictions }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] predictions in
                self?.updatePredictions(predictions)
            })
            .disposed(by: disposeBag)

        // Set up table view with reactive data binding
        setUpTableView(reactor: reactor)
    }

    private func setUpTableView(reactor: TurnipCalculatorReactor) {
        typealias PriceItem = (dayLabel: String, price: Int?, index: Int)

        // 상태 변경 시마다 테이블 뷰 데이터를 갱신하는 Observable 생성
        let pricesObservable: Observable<[PriceItem]> = reactor.state
            .map { $0.turnipPrice.prices }
            .distinctUntilChanged()
            .map { prices -> [PriceItem] in
                let dayLabels = TurnipPrice.dayLabels
                return dayLabels.enumerated().map { index, dayLabel in
                    let price: Int? = prices[safe: index] ?? nil
                    return (dayLabel: dayLabel, price: price, index: index)
                }
            }

        pricesObservable
            .bind(to: priceTableView.rx.items(
                cellIdentifier: TurnipPriceInputCell.reuseIdentifier,
                cellType: TurnipPriceInputCell.self
            )) { [weak self] _, item, cell in
                cell.configure(
                    dayLabel: item.dayLabel,
                    price: item.price,
                    index: item.index
                ) { idx, priceText in
                    self?.priceInputRelay.accept((idx, priceText))
                }
            }
            .disposed(by: disposeBag)
    }

    private func updatePriceInputs(turnipPrice: TurnipPrice) {
        if let buyPrice = turnipPrice.buyPrice {
            buyPriceTextField.text = "\(buyPrice)"
        } else {
            buyPriceTextField.text = nil
        }
        // 테이블뷰는 Rx 바인딩을 통해 자동 업데이트되므로 reloadData 호출 불필요
    }

    private func updatePredictions(_ predictions: [TurnipPrediction]) {
        // Remove existing prediction views
        predictionStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if predictions.isEmpty || predictions.first?.pattern == .unknown {
            let emptyLabel = UILabel()
            emptyLabel.text = "Enter prices to see predictions".localized
            emptyLabel.font = .preferredFont(for: .body, weight: .regular)
            emptyLabel.textColor = .acSecondaryText
            emptyLabel.textAlignment = .center
            predictionStackView.addArrangedSubview(emptyLabel)
            return
        }

        // Add prediction views (max 3)
        for prediction in predictions.prefix(3) {
            let predictionView = TurnipPredictionView()
            predictionView.configure(with: prediction)
            predictionStackView.addArrangedSubview(predictionView)
        }
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
