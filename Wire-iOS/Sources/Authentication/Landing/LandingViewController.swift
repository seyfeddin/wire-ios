//
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

import UIKit
import WireSystem
import WireTransport
import WireSyncEngine

protocol LandingViewControllerDelegate {
    func landingViewControllerDidChooseCreateAccount()
    func landingViewControllerDidChooseCreateTeam()
    func landingViewControllerDidChooseLogin()
    func landingViewControllerDidChooseEnterpriseLogin()
    func landingViewControllerDidChooseSSOLogin()
}

/// Landing screen for choosing how to authenticate.
final class LandingViewController: AuthenticationStepViewController {

    // MARK: - State

    weak var authenticationCoordinator: AuthenticationCoordinator?

    var delegate: LandingViewControllerDelegate? {
        return authenticationCoordinator
    }

    // MARK: - UI Styles

    static let semiboldFont = FontSpec(.large, .semibold).font!

    static let buttonTitleAttribute: [NSAttributedString.Key: AnyObject] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = .center

        return [.foregroundColor: UIColor.Team.textColor, .paragraphStyle: alignCenterStyle, .font: semiboldFont]
    }()

    static let buttonSubtitleAttribute: [NSAttributedString.Key: AnyObject] = {
        let alignCenterStyle = NSMutableParagraphStyle()
        alignCenterStyle.alignment = .center
        alignCenterStyle.paragraphSpacingBefore = 4
        alignCenterStyle.lineSpacing = 4

        let lightFont = FontSpec(.normal, .light).font!

        return [.foregroundColor: UIColor.Team.textColor, .paragraphStyle: alignCenterStyle, .font: lightFont]
    }()

    // MARK: - UI Elements

    private let contentView = UIView()

    private let topStack: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.axis = .vertical

        return stackView
    }()

    private let logoView: UIImageView = {
        let image = UIImage(named: "wire-logo-black")
        let imageView = UIImageView(image: image)
        imageView.accessibilityIdentifier = "WireLogo"
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.Team.textColor
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel(key: "landing.welcome_message".localized,
                            size: .normal,
                            weight: .bold,
                            color: .landingScreen,
                            variant: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private let subMessageLabel: UILabel = {
        let label = UILabel(key: "landing.welcome_submessage".localized,
                            size: .normal,
                            weight: .regular,
                            color: .landingScreen,
                            variant: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()

    private let loginButton: Button = {
        let button = Button(style: .full, variant: .light, titleLabelFont: .smallSemiboldFont)
        button.accessibilityIdentifier = "Login"
        button.setTitle("landing.login.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(loginButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private let enterpriseLoginButton: Button = {
        let button = Button(style: .empty,
                            variant: .light,
                            titleLabelFont: .smallSemiboldFont)
        button.accessibilityIdentifier = "Enterprise Login"
        button.setTitle("landing.login.enterprise.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(enterpriseLoginButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private let loginWithEmailButton: Button = {
        let button = Button(style: .full, variant: .light, titleLabelFont: .smallSemiboldFont)
        button.accessibilityIdentifier = "Login with email"
        button.setTitle("landing.login.email.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(loginButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private let loginWithSSOButton: Button = {
        let button = Button(style: .empty, variant: .light, titleLabelFont: .smallSemiboldFont)
        button.accessibilityIdentifier = "Log in with SSO"
        button.setTitle("landing.login.sso.button.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(ssoLoginButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private let createAccoutInfoLabel: UILabel = {
        let label = UILabel(key: "landing.create_account.infotitle".localized,
                            size: .small,
                            weight: .regular,
                            color: .landingScreen,
                            variant: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private let createAccountButton: Button = {
        let button = Button(style: .empty,
                            variant: .light,
                            titleLabelFont: .smallSemiboldFont)
        button.setBorderColor(UIColor(white: 1.0, alpha: 0.0), for: .normal)
        button.setBorderColor(UIColor(white: 1.0, alpha: 0.0), for: .highlighted)
        button.accessibilityIdentifier = "Create An Account"
        button.setTitle("landing.create_account.title".localized, for: .normal)
        button.addTarget(self,
                         action: #selector(createAccountButtonTapped(_:)),
                         for: .touchUpInside)

        return button
    }()

    private let loginButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        return stackView
    }()

    // MARK: - Constraints

    var topStackTopConstraint = NSLayoutConstraint()
    var topStackTopConstraintConstant: CGFloat {
        return traitCollection.horizontalSizeClass == .compact ? 42.0 : 200.0
    }
    var contentViewWidthConstraint = NSLayoutConstraint()
    var contentViewLeadingConstraint = NSLayoutConstraint()
    var contentViewTrailingConstraint = NSLayoutConstraint()

    var messageLabelLeadingConstraint = NSLayoutConstraint()
    var messageLabelTrailingConstraint = NSLayoutConstraint()
    var messageLabelLabelConstraintsConstant: CGFloat {
        return traitCollection.horizontalSizeClass == .compact ? 0.0 : 72.0
    }

    var subMessageLabelLeadingConstraint = NSLayoutConstraint()
    var subMessageLabelTrailingConstraint = NSLayoutConstraint()
    var subMessageLabelConstraintsConstant: CGFloat {
        return traitCollection.horizontalSizeClass == .compact ? 0.0 : 24.0
    }

    var createAccoutInfoLabelTopConstraint = NSLayoutConstraint()
    var createAccoutButtomBottomConstraint = NSLayoutConstraint()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Team.background

        configureSubviews()
        configureConstraints()

        configureAccessibilityElements()

        updateBarButtonItem()
        disableTrackingIfNeeded()
        updateButtons()
        updateCustomBackendLabels()

        NotificationCenter.default.addObserver(forName: AccountManagerDidUpdateAccountsNotificationName,
                                               object: SessionManager.shared?.accountManager,
                                               queue: .main) { _ in
                self.updateBarButtonItem()
                self.disableTrackingIfNeeded()
        }

        NotificationCenter.default.addObserver(forName: BackendEnvironment.backendSwitchNotification,
                                               object: nil,
                                               queue: .main) { _ in
            self.updateCustomBackendLabels()
            self.updateButtons()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: logoView)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .compatibleDarkContent
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        activateRightConstraint()
        setConstraintsConstants()
    }

    func configure(with featureProvider: AuthenticationFeatureProvider) {
        enterpriseLoginButton.isHidden = !featureProvider.allowDirectCompanyLogin
    }

    private func configureSubviews() {
        if #available(iOS 11, *) {
            additionalSafeAreaInsets.top = -44
        }

        topStack.addArrangedSubview(logoView)

        view.addSubview(topStack)

        contentView.addSubview(messageLabel)
        contentView.addSubview(subMessageLabel)
        buttonStackView.addArrangedSubview(loginButton)
        buttonStackView.addArrangedSubview(enterpriseLoginButton)
        buttonStackView.addArrangedSubview(loginWithEmailButton)
        buttonStackView.addArrangedSubview(loginWithSSOButton)
        contentView.addSubview(buttonStackView)

        view.addSubview(createAccoutInfoLabel)
        view.addSubview(createAccountButton)
        view.addSubview(contentView)
    }

    private func configureConstraints() {
        disableAutoresizingMaskTranslationViews()
        createAndAddConstraints()
        activateRightConstraint()
    }

    private func activateRightConstraint() {
        [contentViewLeadingConstraint,
         contentViewTrailingConstraint,
         createAccoutButtomBottomConstraint].forEach {
            $0.isActive = traitCollection.horizontalSizeClass == .compact
        }

        [contentViewWidthConstraint,
         createAccoutInfoLabelTopConstraint].forEach {
             $0.isActive = traitCollection.horizontalSizeClass != .compact
         }
    }

    private func setConstraintsConstants() {
        topStackTopConstraint.constant = topStackTopConstraintConstant
        messageLabelLeadingConstraint.constant = -messageLabelLabelConstraintsConstant
        messageLabelTrailingConstraint.constant = messageLabelLabelConstraintsConstant
        subMessageLabelLeadingConstraint.constant = -subMessageLabelConstraintsConstant
        subMessageLabelTrailingConstraint.constant = subMessageLabelConstraintsConstant
    }

    private func disableAutoresizingMaskTranslationViews() {
        [
            topStack,
            contentView,
            buttonStackView,
            createAccountButton,
            messageLabel,
            subMessageLabel,
            createAccoutInfoLabel
            ].prepareForLayout()
    }

    private func createAndAddConstraints() {

        topStackTopConstraint = topStack.topAnchor.constraint(equalTo: view.safeTopAnchor,
                                                              constant: topStackTopConstraintConstant)

        contentViewWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 375)
        contentViewLeadingConstraint = contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                                            constant: 24)
        contentViewTrailingConstraint = contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                                              constant: -24)

        messageLabelLeadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                                              constant: -messageLabelLabelConstraintsConstant)
        messageLabelTrailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                                                constant: messageLabelLabelConstraintsConstant)

        subMessageLabelLeadingConstraint = subMessageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                                                    constant: -subMessageLabelConstraintsConstant)
        subMessageLabelTrailingConstraint = subMessageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                                                      constant: subMessageLabelConstraintsConstant)

        createAccoutInfoLabelTopConstraint = createAccoutInfoLabel.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor,
                                                                                        constant: 98)

        createAccoutButtomBottomConstraint = createAccountButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor,
                                                                                         constant: -35)

        NSLayoutConstraint.activate([
            // top stack view
            topStackTopConstraint,
            topStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // logoView
            logoView.heightAnchor.constraint(lessThanOrEqualToConstant: 31),

            // content view,
            contentViewWidthConstraint,
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentViewLeadingConstraint,
            contentViewTrailingConstraint,

            // message label
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageLabelLeadingConstraint,
            messageLabelTrailingConstraint,
            messageLabel.bottomAnchor.constraint(equalTo: subMessageLabel.topAnchor, constant: -16),

            // submessage label

            subMessageLabelLeadingConstraint,
            subMessageLabelTrailingConstraint,
            subMessageLabel.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -48),

            // buttons stack view
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            enterpriseLoginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithEmailButton.heightAnchor.constraint(equalToConstant: 48),
            loginWithSSOButton.heightAnchor.constraint(equalToConstant: 48),

            // create an label
            createAccoutInfoLabelTopConstraint, // iPad
            createAccoutInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createAccoutInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createAccoutInfoLabel.bottomAnchor.constraint(equalTo: createAccountButton.topAnchor),

            // create an button
            createAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createAccountButton.heightAnchor.constraint(equalToConstant: 24),
            createAccoutButtomBottomConstraint // iPhone
        ])
    }

    private func configureRegularSizeClassFont() {
        messageLabel.font = UIFont.boldSystemFont(ofSize: 24)
        subMessageLabel.font = FontSpec(.normal, .regular).font
        createAccoutInfoLabel.font = UIFont.systemFont(ofSize: 14)
        createAccountButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }

    // MARK: - Adaptivity Events

    private func updateLogoView() {
        logoView.isHidden = isCustomBackend
    }

    var isCustomBackend: Bool {
        switch BackendEnvironment.shared.environmentType.value {
        case .production, .staging, .qaDemo, .qaDemo2, .anta, .bella, .chala:
            return false
        case .custom:
            return true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isIPadRegular() || isCustomBackend {
            topStack.spacing = 32
        } else if view.frame.height <= 640 {
            topStack.spacing = view.frame.height / 8
        } else {
            topStack.spacing = view.frame.height / 6
        }

        updateLogoView()
    }

    private func updateBarButtonItem() {
        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            navigationItem.rightBarButtonItem = nil
        } else {
            let cancelItem = UIBarButtonItem(icon: .cross, target: self, action: #selector(cancelButtonTapped))
            cancelItem.accessibilityIdentifier = "CancelButton"
            cancelItem.accessibilityLabel = "general.cancel".localized
            navigationItem.rightBarButtonItem = cancelItem
        }
    }

    private var productName: String {
        guard let name = Bundle.appMainBundle.infoForKey("CFBundleDisplayName") else {
            fatal("unable to access CFBundleDisplayName")
        }
        return name
    }

    private func updateCustomBackendLabels() {
        switch BackendEnvironment.shared.environmentType.value {
        case .production, .staging, .qaDemo, .qaDemo2, .anta, .bella, .chala:
            messageLabel.text = "landing.welcome_message".localized
            subMessageLabel.text = "landing.welcome_submessage".localized
        case .custom(url: let url):
            guard SecurityFlags.customBackend.isEnabled else {
                return
            }
            messageLabel.text = "landing.custom_backend.title".localized(args: BackendEnvironment.shared.title)
            subMessageLabel.text = url.absoluteString
        }
        updateLogoView()
    }

    private func updateButtons() {
        enterpriseLoginButton.isHidden = isCustomBackend
        loginButton.isHidden = isCustomBackend
        createAccoutInfoLabel.isHidden = isCustomBackend
        createAccountButton.isHidden = isCustomBackend
        loginWithSSOButton.isHidden = !isCustomBackend
        loginWithEmailButton.isHidden = !isCustomBackend
    }

    private func disableTrackingIfNeeded() {
        if SessionManager.shared?.firstAuthenticatedAccount == nil {
            TrackingManager.shared.disableCrashSharing = true
            TrackingManager.shared.disableAnalyticsSharing = true
        }
    }

    // MARK: - Accessibility

    private func configureAccessibilityElements() {
        logoView.isAccessibilityElement = true
        logoView.accessibilityLabel = "landing.header".localized
        logoView.accessibilityTraits.insert(.header)
    }

    override func accessibilityPerformEscape() -> Bool {
        guard SessionManager.shared?.firstAuthenticatedAccount != nil else {
            return false
        }

        cancelButtonTapped()
        return true
    }

    // MARK: - Button tapped target

    @objc
    private func createAccountButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseCreateAccount()
    }

    @objc
    private func createTeamButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseCreateTeam()
    }

    @objc
    private func loginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseLogin()
    }

    @objc
    private func enterpriseLoginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseEnterpriseLogin()
    }

    @objc
    private func ssoLoginButtonTapped(_ sender: AnyObject!) {
        delegate?.landingViewControllerDidChooseSSOLogin()
    }

    @objc
    private func cancelButtonTapped() {
        guard let account = SessionManager.shared?.firstAuthenticatedAccount else { return }
        SessionManager.shared!.select(account)
    }

    // MARK: - AuthenticationCoordinatedViewController

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // no-op
    }

    func displayError(_ error: Error) {
        // no-op
    }
}
