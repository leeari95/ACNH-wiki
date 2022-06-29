//
//  ProgressView.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2022/06/15.
//

import UIKit

class ProgressView: UIStackView {
    
    private var maxCount: Float = 0
    private var height: CGFloat = 30
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var progressBar: ProgressBar = {
        let progressBar = ProgressBar()
        progressBar.setHeight(height/2.8)
        return progressBar
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.font = .preferredFont(for: .footnote, weight: .semibold)
        label.textColor = .acText
        label.textAlignment = .right
        return label
    }()

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 10
        
        addArrangedSubviews(iconImageView, progressBar, progressLabel)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: height),
            iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor)
        ])
    }
}

extension ProgressView {
    convenience init(icon: String, progress: Int, maxCount: Int) {
        self.init(frame: .zero)
        self.maxCount = Float(maxCount)
        self.progressLabel.text = "\(progress) / \(maxCount)"
        self.iconImageView.image = UIImage(named: icon)
        self.progressBar.setProgress(Float(progress) / self.maxCount, animated: true)
    }
}
