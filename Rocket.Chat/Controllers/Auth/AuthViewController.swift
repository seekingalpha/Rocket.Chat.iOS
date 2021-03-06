//
//  AuthViewController.swift
//  Rocket.Chat
//
//  Created by Rafael K. Streit on 7/6/16.
//  Copyright © 2016 Rocket.Chat. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import OnePasswordExtension

final class AuthViewController: BaseViewController {
    var interactor: AuthInteractor?
    internal var connecting = false
    var serverURL: URL?
    var serverPublicSettings: AuthSettings?
    var login: String?
    var password: String?
    var stateMachine: AuthStateMachine?
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var viewFields: UIView!
    @IBOutlet weak var onePasswordButton: UIButton! {
        didSet {
            onePasswordButton.isHidden = !OnePasswordExtension.shared().isAppExtensionAvailable()
        }
    }

    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var visibleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textInfoLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!

    var customActivityIndicator: LoaderView!

    @IBOutlet weak var activityIndicatorContainer: UIView! {
        didSet {
            let width = activityIndicatorContainer.bounds.width
            let height = activityIndicatorContainer.bounds.height
            let frame = CGRect(x: 0, y: 0, width: width, height: height)
            let activityIndicator = LoaderView(frame: frame)
            activityIndicator.color = .white
            activityIndicatorContainer.addSubview(activityIndicator)
            self.customActivityIndicator = activityIndicator
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            navigationBar.isTranslucent = true
            navigationController?.view?.backgroundColor = .clear
        }
        AuthManager.recoverAuthIfNeeded()
        self.textFieldUsername.text = self.login
        self.textFieldPassword.text = self.password
        self.stateMachine?.switchState(state: FirstLoadingState(authViewController: self))
        self.stateMachine?.execute()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Keyboard Handlers
    override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            visibleViewBottomConstraint.constant = keyboardSize.height
        }
    }

    override func keyboardWillHide(_ notification: Notification) {
        visibleViewBottomConstraint.constant = 0
    }

    internal func handleAuthenticationResponse(_ response: SocketResponse) {
        stopLoading()

//        if response.isError() {
//            if let error = response.result["error"].dictionary {
//                let code = error["error"]?.int
//                if code != nil && code == 403 {
//                    performSegue(withIdentifier: "403", sender: nil)
//                } else {
//                    let alert = UIAlertController(
//                        title: localized("error.socket.default_error_title"),
//                        message: error["message"]?.string ?? localized("error.socket.default_error_message"),
//                        preferredStyle: .alert
//                    )
//
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                    present(alert, animated: true, completion: nil)
//                }
//            }
//            self.stateMachine?.error()
//        } else {
            self.stateMachine?.success()
//        }
    }

    internal func loginResponse(_ response: HTTPResponse) {
        stopLoading()
        if !response.isError {
            self.stateMachine?.success()
        } else {
            self.stateMachine?.error()
        }

//        if response.isError() {
//            if let error = response.result["error"].dictionary {
//                let code = error["error"]?.int
//                if code != nil && code == 403 {
//                    performSegue(withIdentifier: "403", sender: nil)
//                } else {
//                    let alert = UIAlertController(
//                        title: localized("error.socket.default_error_title"),
//                        message: error["message"]?.string ?? localized("error.socket.default_error_message"),
//                        preferredStyle: .alert
//                    )
//
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                    present(alert, animated: true, completion: nil)
//                }
//            }
//            self.stateMachine?.error()
//        } else {
//        }
    }

    // MARK: Loaders
    func startLoading() {
        textFieldUsername.alpha = 0.5
        textFieldPassword.alpha = 0.5
        connecting = true
        activityIndicator.startAnimating()
        textFieldUsername.resignFirstResponder()
        textFieldPassword.resignFirstResponder()
    }

    func stopLoading() {
        textFieldUsername.alpha = 1
        textFieldPassword.alpha = 1
        connecting = false
        activityIndicator.stopAnimating()
    }

    // MARK: IBAction
    func authenticateWithUsernameOrEmail() {
        let email = textFieldUsername.text ?? ""
        let password = textFieldPassword.text ?? ""
        startLoading()
        let params = ["email": email,
                      "password": password]
        AuthManager.auth(params: params, completion: self.loginResponse)
    }

    @IBAction func buttonAuthenticateGoogleDidPressed(_ sender: Any) {
        authenticateWithGoogle()
    }

    @IBAction func buttonTermsDidPressed(_ sender: Any) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.serverURL?.host

        if var newURL = components.url {
            newURL = newURL.appendingPathComponent("terms-of-service")

            let controller = SFSafariViewController(url: newURL)
            present(controller, animated: true, completion: nil)
        }
    }

    @IBAction func buttonPolicyDidPressed(_ sender: Any) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.serverURL?.host

        if var newURL = components.url {
            newURL = newURL.appendingPathComponent("privacy-policy")

            let controller = SFSafariViewController(url: newURL)
            present(controller, animated: true, completion: nil)
        }
    }

    @IBAction func buttonOnePasswordDidPressed(_ sender: Any) {
        let siteURL = serverPublicSettings?.siteURL ?? ""
        OnePasswordExtension.shared().findLogin(forURLString: siteURL, for: self, sender: sender) { [weak self] (login, _) in
            if login == nil {
                return
            }

            self?.textFieldUsername.text = login?[AppExtensionUsernameKey] as? String
            self?.textFieldPassword.text = login?[AppExtensionPasswordKey] as? String
            self?.authenticateWithUsernameOrEmail()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         UIApplication.shared.statusBarStyle = .lightContent
    }

    func showChat() {
        // Open chat
        let storyboardChat = UIStoryboard(name: "Chat", bundle: Bundle.main)
        let controller = storyboardChat.instantiateInitialViewController()
        let application = UIApplication.shared
        if let window = application.keyWindow {
            window.rootViewController = controller
        }
    }

    func alertInvalidURL() {
        let alert = UIAlertController(
            title: localized("alert.connection.invalid_url.title"),
            message: localized("alert.connection.invalid_url.message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: localized("global.ok"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func alertWrongServerVersion(version: String, minVersion: String) {
        let alert = UIAlertController(
            title: localized("alert.connection.invalid_version.title"),
            message: String(format: localized("alert.connection.invalid_version.message"), version, minVersion),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: localized("global.ok"), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func finishExecution(nextState: AuthState?) {
        self.stateMachine?.switchState(state: nextState)
        self.stateMachine?.execute()
    }
    @IBAction func signIn() {
        self.stateMachine?.success()
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return !connecting
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if connecting {
            return false
        }

        if textField == textFieldUsername {
            textFieldPassword.becomeFirstResponder()
        }

        if textField == textFieldPassword {
            self.stateMachine?.success()
        }
        return true
    }
}
