//
//  ItemKeywordView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/14.
//

import UIKit
import RxSwift
import RxCocoa
import ACNHCore
import ACNHShared

final class ItemKeywordView: UIView {

    private let disposeBag = DisposeBag()

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        flowLayout.minimumInteritemSpacing = 20
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        flowLayout.minimumLineSpacing = 20
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.registerNib(KeywordCell.self)
        return collectionView
    }()

    var didTapKeyword: Observable<String> {
        return collectionView.rx.modelSelected(String.self).asObservable()
    }

    convenience init(item: Item) {
        self.init(frame: .zero)
        configure(in: item)
    }

    private func configure(in item: Item) {
        addSubviews(collectionView)
        let heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 50)
        heightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            collectionView.widthAnchor.constraint(equalTo: widthAnchor),
            heightConstraint
        ])

        let keyword = Set(item.keyword)

        Observable.just(keyword)
            .bind(to: collectionView.rx.items(cellIdentifier: KeywordCell.className, cellType: KeywordCell.self)) { _, text, cell in
                cell.setUp(title: text)
            }.disposed(by: disposeBag)
    }
}
