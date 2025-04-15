//
//  StringExtension.swift
//  WordSearch
//
//  Created by Phil Wright on 3/10/25.
//

import UIKit

// MARK: - UI Related Extensions
extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Color Related Extensions
extension UIColor {
    /// Get a random color with saturation, brightness, and alpha
    ///
    /// - Returns: the uicolor
    static var random: UIColor {
        return .init(hue: .random(in: 0...1), saturation: 0.5, brightness: 0.9, alpha: 1)
    }
}

// MARK: - Navigation Related Extensions
extension UIViewController {
    func pushToViewController(_ viewController: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(viewController, animated: animated)
    }
    
    func popViewController(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }
}

// MARK: - Number Related Extensions
extension Int {
    /// Get display formatted time from number of seconds
    /// E.g. 65s = 01:05
    ///
    /// - Returns: the display string
    func formattedTime() -> String {
        let seconds: Int = self % 60
        let minutes: Int = self / 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Keyboard Handling Extensions
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
