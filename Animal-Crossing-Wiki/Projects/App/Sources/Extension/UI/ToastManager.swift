//
//  ToastManager.swift
//  Animal-Crossing-Wiki
//
//  Created by Ari on 2026/03/01.
//

import UIKit

final class ToastManager {

    static let shared = ToastManager()
    private init() {}

    private var toastWindow: UIWindow?
    private var currentToast: ToastView?
    private var referenceCount = 0
    private var timeoutWork: DispatchWorkItem?

    // MARK: - Public API

    /// 단순 토스트 표시. timeout > 0이면 자동 dismiss.
    func show(message: String, timeout: TimeInterval = 0) {
        guard currentToast == nil else {
            return
        }
        
        guard let window = makeWindowIfNeeded() else {
            return
        }
        
        let toast = ToastView(message: message)
        currentToast = toast
        toast.show(in: window)
        if timeout > 0 {
            scheduleTimeout(timeout)
        }
    }

    /// 레퍼런스 카운팅 기반 표시. 모든 decrementAndDismiss 호출 후 dismiss.
    func incrementAndShow(message: String, timeout: TimeInterval = 60) {
        referenceCount += 1
        guard currentToast == nil else {
            return
        }

        guard let window = makeWindowIfNeeded() else {
            return
        }

        let toast = ToastView(message: message)
        currentToast = toast
        toast.show(in: window)
        scheduleTimeout(timeout)
    }

    /// 레퍼런스 카운트 감소. 0이 되면 dismiss.
    func decrementAndDismiss() {
        referenceCount = max(referenceCount - 1, 0)
        guard referenceCount == 0 else {
            return
        }

        dismiss()
    }

    /// 즉시 dismiss.
    func dismiss() {
        timeoutWork?.cancel()
        timeoutWork = nil
        referenceCount = 0
        currentToast?.dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.currentToast = nil
            self?.teardownWindow()
        }
    }

    // MARK: - Window Management

    @discardableResult
    private func makeWindowIfNeeded() -> UIWindow? {
        if let existing = toastWindow {
            return existing
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return nil
        }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .statusBar + 1
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        window.rootViewController = rootVC
        window.isHidden = false
        toastWindow = window
        return window
    }

    private func teardownWindow() {
        toastWindow?.isHidden = true
        toastWindow = nil
    }

    private func scheduleTimeout(_ timeout: TimeInterval) {
        timeoutWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }
        timeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: work)
    }
}
