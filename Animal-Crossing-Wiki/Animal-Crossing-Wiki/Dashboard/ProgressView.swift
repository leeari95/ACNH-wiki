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
        imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        return imageView
    }()
    
    private lazy var progressBar: UIProgressView = {
        let progressBar = UIProgressView()
        progressBar.heightAnchor.constraint(equalToConstant: height / 2.5).isActive = true
        let radius = progressBar.layer.bounds.height * 1.5
        progressBar.layer.cornerRadius = radius
        progressBar.clipsToBounds = true
        progressBar.layer.sublayers?.first?.cornerRadius = radius
        progressBar.subviews.first?.clipsToBounds = true
        progressBar.layer.sublayers?[1].cornerRadius = radius
        progressBar.subviews[1].clipsToBounds = true
        progressBar.tintColor = .acHeaderBackground
        return progressBar
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.font = .preferredFont(for: .footnote, weight: .semibold)
        label.textColor = .acText
        label.textAlignment = .right
        label.widthAnchor.constraint(equalToConstant: 46).isActive = true
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
            progressBar.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            progressLabel.leadingAnchor.constraint(equalTo: progressBar.trailingAnchor, constant: 10)
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
