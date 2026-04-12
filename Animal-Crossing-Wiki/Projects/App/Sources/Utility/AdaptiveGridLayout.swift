//
//  AdaptiveGridLayout.swift
//  Animal-Crossing-Wiki
//

import UIKit

enum AdaptiveGridLayout {

    static func grid(
        itemWidth: CGFloat,
        itemHeight: CGFloat,
        spacing: CGFloat = 10,
        sectionInsets: NSDirectionalEdgeInsets = .init(top: 10, leading: 20, bottom: 10, trailing: 20)
    ) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let availableWidth = environment.container.effectiveContentSize.width
                - sectionInsets.leading - sectionInsets.trailing
            let columns = max(3, Int(availableWidth / (itemWidth + spacing)))
            let groupWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            let itemLayoutSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .estimated(itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(
                    widthDimension: groupWidth,
                    heightDimension: .estimated(itemHeight)
                ),
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(spacing)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = sectionInsets
            return section
        }
    }

    static func iconGrid(
        itemSize: CGFloat,
        spacing: CGFloat = 8
    ) -> UICollectionViewCompositionalLayout {
        grid(
            itemWidth: itemSize,
            itemHeight: itemSize,
            spacing: spacing,
            sectionInsets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        )
    }
}
