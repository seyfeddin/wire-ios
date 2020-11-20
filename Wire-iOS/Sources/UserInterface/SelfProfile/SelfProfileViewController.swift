//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireSyncEngine
import WireCommonComponents
import WireUtilities

/**
 * The first page of the user settings.
 */

final class SelfProfileViewController: UIViewController {

    /// The user that is viewing their settings.
    let selfUser: SettingsSelfUser

    var userRightInterfaceType: UserRightInterface.Type = UserRight.self
    var settingsCellDescriptorFactory: SettingsCellDescriptorFactory? = nil
    var rootGroup: (SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType)? = nil

    // MARK: - Views

    private let settingsController: SettingsTableViewController
    private let accountSelectorController = AccountSelectorController()
    private let profileContainerView = UIView()
    private let profileHeaderViewController: ProfileHeaderViewController

    // MARK: - AppLock
    private var callback: ResultHandler?

    // MARK: - Configuration

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var userCanSetProfilePicture: Bool {
        return userRightInterfaceType.selfUserIsPermitted(to: .editProfilePicture)
    }

    // MARK: - Initialization

    /**
     * Creates the settings screen with the specified user and permissions.
     * - parameter selfUser: The current user.
     * - parameter userRightInterfaceType: The type of object to determine the user permissions.
     */

    init(selfUser: SettingsSelfUser,
         userRightInterfaceType: UserRightInterface.Type = UserRight.self,
         userSession: UserSessionSwiftInterface? = ZMUserSession.shared()) {
        
        self.selfUser = selfUser

        // Create the settings hierarchy
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: userSession, selfUser: selfUser)
		let settingsCellDescriptorFactory = SettingsCellDescriptorFactory(settingsPropertyFactory: settingsPropertyFactory, userRightInterfaceType: userRightInterfaceType)
        let rootGroup = settingsCellDescriptorFactory.rootGroup(isTeamMember: selfUser.isTeamMember)
        settingsController = rootGroup.generateViewController()! as! SettingsTableViewController
        profileHeaderViewController = ProfileHeaderViewController(user: selfUser, viewer: selfUser, options: selfUser.isTeamMember ? [.allowEditingAvailability] : [.hideAvailability])

		self.userRightInterfaceType = userRightInterfaceType
		self.settingsCellDescriptorFactory = settingsCellDescriptorFactory
        self.rootGroup = rootGroup

        super.init(nibName: nil, bundle: nil)
        settingsPropertyFactory.delegate = self

        if selfUser.isTeamMember {
            userSession?.enqueue {
                selfUser.refreshTeamData()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        profileHeaderViewController.colorSchemeVariant = .dark
        profileHeaderViewController.imageView.addTarget(self, action: #selector(userDidTapProfileImage), for: .touchUpInside)
        
        addChild(profileHeaderViewController)
        profileContainerView.addSubview(profileHeaderViewController.view)
        view.addSubview(profileContainerView)
        profileHeaderViewController.didMove(toParent: self)

        if userCanSetProfilePicture {
            profileHeaderViewController.options.insert(.allowEditingProfilePicture)
        }

        addChild(settingsController)
        view.addSubview(settingsController.view)
        settingsController.didMove(toParent: self)

        settingsController.tableView.isScrollEnabled = false

        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        configureAccountTitle()
        createConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !presentNewLoginAlertControllerIfNeeded() {
            presentUserSettingChangeControllerIfNeeded()
        }
    }

    private func configureAccountTitle() {
        if SessionManager.shared?.accountManager.accounts.count > 1 {
            navigationItem.titleView = accountSelectorController.view
        } else {
            title = "self.account".localized(uppercased: true)
        }
    }
    
    private func createConstraints() {
        profileHeaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        profileContainerView.translatesAutoresizingMaskIntoConstraints = false
        settingsController.view.translatesAutoresizingMaskIntoConstraints = false
        accountSelectorController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // accountSelectorController
            accountSelectorController.view.heightAnchor.constraint(equalToConstant: 44),

            // profileContainerView
            profileContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileContainerView.topAnchor.constraint(equalTo: safeTopAnchor),
            profileContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // profileView
            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: profileContainerView.leadingAnchor),
            profileHeaderViewController.view.topAnchor.constraint(greaterThanOrEqualTo: profileContainerView.topAnchor),
            profileHeaderViewController.view.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor),
            profileHeaderViewController.view.bottomAnchor.constraint(lessThanOrEqualTo: profileContainerView.bottomAnchor),
            profileHeaderViewController.view.centerYAnchor.constraint(equalTo: profileContainerView.centerYAnchor),

            // settingsControllerView
            settingsController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsController.view.topAnchor.constraint(equalTo: profileContainerView.bottomAnchor),
            settingsController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsController.view.bottomAnchor.constraint(equalTo: safeBottomAnchor),
        ])
    }

    // MARK: - Events

    @objc func userDidTapProfileImage(sender: UserImageView) {
        guard userCanSetProfilePicture else { return }
        let profileImageController = ProfileSelfPictureViewController()
        self.present(profileImageController, animated: true, completion: .none)
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }

}

// MARK: - SettingsPropertyFactoryDelegate

extension SelfProfileViewController: SettingsPropertyFactoryDelegate {
    private var topViewController: SpinnerCapableViewController? {
        navigationController?.topViewController as? SpinnerCapableViewController
    }

    func asyncMethodDidStart(_ settingsPropertyFactory: SettingsPropertyFactory) {
        // topViewController is SettingsTableViewController
        topViewController?.isLoadingViewVisible = true
    }

    func asyncMethodDidComplete(_ settingsPropertyFactory: SettingsPropertyFactory) {
        topViewController?.isLoadingViewVisible = false
    }

    
    /// Create or delete custom passcode when appLock option did change
    /// If custom passcode is not enabled, no action is taken
    ///
    /// - Parameters:
    ///   - settingsPropertyFactory: caller of this delegate method
    ///   - newValue: new value of app lock option
    ///   - callback: callback for PasscodeSetupViewController
    func appLockOptionDidChange(_ settingsPropertyFactory: SettingsPropertyFactory,
                                newValue: Bool,
                                callback: @escaping ResultHandler) {
        guard AppLock.rules.useCustomCodeInsteadOfAccountPassword else {
            callback(newValue)
            return
        }
        
        guard newValue else {
            Keychain.deletePasscode()
            callback(newValue)
            
            return
        }
        
        self.callback = callback
        let passcodeSetupViewController = PasscodeSetupViewController(callback: callback, variant: .dark)
        passcodeSetupViewController.passcodeSetupViewControllerDelegate = self
        
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: passcodeSetupViewController)
        
        let wrappedViewController = keyboardAvoidingViewController.wrapInNavigationController(navigationBarClass: DarkBarItemTransparentNavigationBar.self)
        
        let closeItem = passcodeSetupViewController.closeItem

        keyboardAvoidingViewController.navigationItem.leftBarButtonItem = closeItem
                    
        wrappedViewController.presentationController?.delegate = passcodeSetupViewController
        
        UIApplication.shared.topmostViewController()?.present(wrappedViewController, animated: true)
    }
}

extension SelfProfileViewController: PasscodeSetupViewControllerDelegate {
    func passcodeSetupControllerDidFinish(_ viewController: PasscodeSetupViewController) {
        //no-op
    }
    
    func passcodeSetupControllerWasDismissed(_ viewController: PasscodeSetupViewController) {
        // refresh options applock switch
        (topViewController as? SettingsTableViewController)?.refreshData()
    }
}
