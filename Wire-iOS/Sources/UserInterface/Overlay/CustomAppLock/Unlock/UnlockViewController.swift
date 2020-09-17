// Wire
// Copyright (C) 2020 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import UIKit
import WireCommonComponents

/// UnlockViewController
/// 
/// This VC should be wrapped in KeyboardAvoidingViewController as the "unlock" button would be covered on 4 inch iPhone
final class UnlockViewController: UIViewController {

    var callback: RequestPasswordController.Callback?

    private let shieldView = UIView.shieldView()
    private let blurView: UIVisualEffectView = UIVisualEffectView.blurView()

    private let stackView: UIStackView = UIStackView.verticalStackView()
    private let upperStackView = UIStackView.verticalStackView()

    private let contentView: UIView = UIView()

    private lazy var unlockButton: Button = {
        let button = Button(style: .fullMonochrome,
                            titleLabelFont: .smallSemiboldFont)

        button.setTitle("unlock.submit_button.title".localized, for: .normal)
        button.isEnabled = false

        button.addTarget(self, action: #selector(onUnlockButtonPressed(sender:)), for: .touchUpInside)

        return button
    }()

    lazy var accessoryTextField: AccessoryTextField = {
        let textField = AccessoryTextField.createPasscodeTextField(kind: .passcode(isNew: false), delegate: self)
        textField.placeholder = "unlock.textfield.placeholder".localized
        textField.delegate = self

        return textField
    }()

    private let titleLabel: UILabel = {
        let label = UILabel(key: "unlock.title_label".localized, size: FontSize.large, weight: .semibold, color: .textForeground, variant: .dark)

        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private static let errorFont = FontSpec(.small, .light).font!.withSize(10)
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = " "
        label.font = errorFont
        label.textColor = UIColor.PasscodeUnlock.error

        return label
    }()

    private let wipeButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = FontSpec(.medium, .medium).font!.withSize(14)
        button.setTitleColor(UIColor.from(scheme: .textForeground, variant: .dark), for: .normal)

        button.setTitle("unlock.wipe_button".localized, for: .normal)

        button.addTarget(self, action: #selector(onWipeButtonPressed(sender:)), for: .touchUpInside)

        return button
    }()

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        view.backgroundColor = .black

        [shieldView, blurView, contentView].forEach {
            view.addSubview($0)
        }

        stackView.distribution = .fill

        // stackview for horizonal spacing except unlockButton
        upperStackView.distribution = .fillProportionally

        upperStackView.isLayoutMarginsRelativeArrangement = true

        upperStackView.layoutMargins = UIEdgeInsets(top: 0,
                                                    left: CGFloat.PasscodeUnlock.textFieldPadding,
                                                    bottom: 0,
                                                    right: CGFloat.PasscodeUnlock.textFieldPadding)

        contentView.addSubview(stackView)

        [titleLabel,
         UILabel.createHintLabel(variant: .dark),
         accessoryTextField,
         errorLabel,
         SpacingView(5),
         wipeButton].forEach {
            upperStackView.addArrangedSubview($0)
        }

        [upperStackView,
         SpacingView(25),
         unlockButton].forEach {
            stackView.addArrangedSubview($0)
        }

        createConstraints()
    }

    // MARK: - status bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        accessoryTextField.becomeFirstResponder()
    }

    private func createConstraints() {

        [shieldView,
         blurView,
         contentView,
         upperStackView,
         stackView].disableAutoresizingMaskTranslation()

        let widthConstraint = contentView.createContentWidthConstraint()

        let contentPadding: CGFloat = 24

        NSLayoutConstraint.activate([
            // nibView
            shieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shieldView.topAnchor.constraint(equalTo: view.topAnchor),
            shieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // blurView
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat.iPhone4_7Inch.width),
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),

            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // unlock Button
            unlockButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight)
        ])
    }

    @objc
    private func onWipeButtonPressed(sender: AnyObject?) {
        let wipeDatabaseViewController = WipeDatabaseWireframe().createWipeDatabaseModule()
        navigationController?.pushViewController(wipeDatabaseViewController, animated: true)
    }

    @discardableResult
    private func unlock() -> Bool {
        guard let passcode = accessoryTextField.text else { return false }

        callback?(passcode)
        return true
    }

    @objc
    private func onUnlockButtonPressed(sender: AnyObject?) {
        unlock()
    }

    func showWrongPasscodeMessage() {
        let textAttachment = NSTextAttachment.textAttachment(for: .exclamationMarkCircle, with: UIColor.PasscodeUnlock.error, iconSize: StyleKitIcon.Size.CreatePasscode.errorIconSize, verticalCorrection: -1, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4))

        let attributedString = NSAttributedString(string: "unlock.error_label".localized) && UnlockViewController.errorFont

        errorLabel.attributedText = NSAttributedString(attachment: textAttachment) + attributedString
        unlockButton.isEnabled = false
    }
}

// MARK: - AccessoryTextFieldDelegate

extension UnlockViewController: AccessoryTextFieldDelegate {
    func buttonPressed(_ sender: UIButton) {
        accessoryTextField.isSecureTextEntry = !accessoryTextField.isSecureTextEntry

        accessoryTextField.updatePasscodeIcon()
    }
}

// MARK: - TextFieldValidationDelegate

extension UnlockViewController: TextFieldValidationDelegate {
    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        unlockButton.isEnabled = error == nil
        errorLabel.text = " "
    }
}

// MARK: - UITextFieldDelegate

extension UnlockViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return unlock()
    }
}
