//
//  TurnipPricePresentationAnimator.swift
//  ACNH-wiki
//
//  Created by Ari on 1/4/26.
//

import UIKit

final class TurnipPricePresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) as? TurnipPriceResultViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        // 딤드 뷰를 containerView에 추가
        let dimmingView = toViewController.dimmingView
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)

        // toView 추가
        toViewController.view.frame = containerView.bounds
        containerView.addSubview(toViewController.view)

        // 초기 상태: 뷰를 화면 아래에 위치
        let screenHeight = containerView.bounds.height
        toViewController.view.transform = CGAffineTransform(translationX: 0, y: screenHeight)

        // 슬라이드 업 + 딤드 배경 페이드 인 동시 애니메이션
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.0,
            options: .curveEaseInOut,
            animations: {
                toViewController.view.transform = .identity
                dimmingView.alpha = 0.3
            },
            completion: { finished in
                transitionContext.completeTransition(finished)
            }
        )
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? TurnipPriceResultViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let screenHeight = containerView.bounds.height
        let dimmingView = fromViewController.dimmingView

        // 슬라이드 다운 + 딤드 배경 페이드 아웃 동시 애니메이션
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                fromViewController.view.transform = CGAffineTransform(translationX: 0, y: screenHeight)
                dimmingView.alpha = 0
            },
            completion: { finished in
                dimmingView.removeFromSuperview()
                fromViewController.view.removeFromSuperview()
                transitionContext.completeTransition(finished)
            }
        )
    }
}
