//
//  TodaysTasksView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit
import RxSwift

class TodaysTasksView: UIView {

    private var viewModel: TodaysTasksSesctionViewModel?
    private let disposeBag = DisposeBag()
    private var heightConstraint: NSLayoutConstraint!
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 40, height: 40)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(IconCell.self)
        return collectionView
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 50
        return stackView
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit", for: .normal)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        return button
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height + 40
        self.heightConstraint.constant = contentHeight == .zero ? 40 : contentHeight
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.heightConstraint.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height
    }
    
    private func configure() {
        addSubviews(collectionView, buttonStackView)
        
        self.heightConstraint = self.collectionView.heightAnchor.constraint(equalToConstant: 40)
        heightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])

        [editButton, resetButton].forEach {
            $0.setTitleColor(.acText, for: .normal)
            $0.titleLabel?.font = .preferredFont(for: .footnote, weight: .bold)
            $0.backgroundColor = .acText.withAlphaComponent(0.2)
            $0.layer.cornerRadius = 12
            $0.widthAnchor.constraint(equalToConstant: 56).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 28).isActive = true
        }
        buttonStackView.addArrangedSubviews(editButton, resetButton)
    }
    
    func bind() {
        let input = TodaysTasksSesctionViewModel.Input(
            didSelectItem: collectionView.rx.itemSelected.asObservable(),
            didTapReset: resetButton.rx.tap.asObservable(),
            didTapEdit: editButton.rx.tap.asObservable()
        )
        let output = viewModel?.transform(input: input, disposeBag: disposeBag)
        
        output?.tasks
            .bind(
                to: collectionView.rx.items(
                    cellIdentifier: IconCell.className,
                    cellType: IconCell.self
                )
            ) { _, item, cell in
                cell.setImage(icon: item.task.icon)
                item.task.progressList[item.progressIndex] ? cell.setAlpha(1) : cell.setAlpha(0.5)
            }.disposed(by: disposeBag)
        
        output?.tasks
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.layoutIfNeeded()
                }
            }).disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                let cell = self.collectionView.cellForItem(at: indexPath) as? IconCell
                cell?.toggle()
            }).disposed(by: disposeBag)
    }
}

extension TodaysTasksView {
    
    convenience init(_ viewModel: TodaysTasksSesctionViewModel) {
        self.init(frame: .zero)
        self.viewModel = viewModel
        bind()
    }
}
