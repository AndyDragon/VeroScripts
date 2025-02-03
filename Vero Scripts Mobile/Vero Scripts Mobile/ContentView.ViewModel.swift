//
//  ContentView.ViewModel.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2025-01-11.
//

import SwiftUI
import SwiftyBeaver

extension ContentView {
    @Observable
    class ViewModel {
        private let logger = SwiftyBeaver.self

        // MARK: Toasts
        var toastViews = [AdvancedToast]()
        var hasModalToasts: Bool {
            return toastViews.count(where: { $0.modal }) > 0
        }

        func dismissToast(
            _ toast: AdvancedToast
        ) {
            toastViews.removeAll(where: { $0 == toast })
        }

        func dismissAllNonBlockingToasts(includeProgress: Bool = false) {
            toastViews.removeAll(where: { !$0.blocking })
            if includeProgress {
                toastViews.removeAll(where: { $0.type == .progress })
            }
        }

        @discardableResult func showToast(
            _ type: AdvancedToastStyle,
            _ title: String,
            _ message: String,
            duration: Double? = nil,
            modal: Bool? = nil,
            blocking: Bool? = nil,
            width: CGFloat? = nil,
            buttonTitle: String? = nil,
            onButtonTapped: (() -> Void)? = nil,
            onDismissed: (() -> Void)? = nil
        ) -> AdvancedToast {
            let advancedToastView = AdvancedToast(
                type: type,
                title: title,
                message: message,
                duration: duration,
                modal: modal,
                blocking: blocking,
                width: width,
                buttonTitle: buttonTitle,
                onButtonTapped: onButtonTapped,
                onDismissed: onDismissed
            )
            toastViews.append(advancedToastView)
            while toastViews.count > 5 {
                toastViews.remove(at: 0)
            }
            return advancedToastView
        }

        @discardableResult func showSuccessToast(
            _ title: String,
            _ message: String
        ) -> AdvancedToast {
            return showToast(.success, title, message)
        }

        @discardableResult func showInfoToast(
            _ title: String,
            _ message: String
        ) -> AdvancedToast {
            return showToast(.info, title, message)
        }
    }
}
