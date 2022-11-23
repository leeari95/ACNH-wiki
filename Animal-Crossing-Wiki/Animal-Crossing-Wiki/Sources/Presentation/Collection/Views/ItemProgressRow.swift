//
//  ItemProgressRow.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/07/10.
//

import UIKit

class ItemProgressRow: UITableViewCell {
    
    private var progressView: ProgressView = .init(category: .art, barHeight: 40)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .acText.withAlphaComponent(0.3)
        
        contentView.addSubviews(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        progressView.updateView(category: .art)
    }
    
    func setUp(for category: Category) {
        progressView.updateView(category: category)
    }
}
