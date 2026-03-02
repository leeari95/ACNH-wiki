//
//  CloudSyncSplashViewController.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2026/03/01.
//

import UIKit

final class CloudSyncSplashViewController: UIViewController {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "App-Icon"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "launchBackground") ?? .acBackground

        view.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startIconAnimation()
    }

    private func startIconAnimation() {
        let bounce = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounce.values = [0, -8, 0, -4, 0]
        bounce.keyTimes = [0, 0.3, 0.5, 0.7, 1.0]
        bounce.duration = 1.2
        bounce.repeatCount = .infinity
        bounce.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeIn)
        ]
        iconImageView.layer.add(bounce, forKey: "bounce")
    }
}
