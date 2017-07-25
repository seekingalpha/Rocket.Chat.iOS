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
import RxSwift
import RxCocoa

final class AuthViewController: BaseViewController {
    var interactor: AuthInteractor?
    internal var connecting = false
    var serverURL: URL?
    var serverPublicSettings: AuthSettings?
    let disposeBag = DisposeBag()
    var login: String?
    var password: String?

    @IBOutlet weak var viewFields: UIView! {
        didSet {
            viewFields.layer.cornerRadius = 4
            viewFields.layer.borderColor = UIColor.RCLightGray().cgColor
            viewFields.layer.borderWidth = 0.5
        }
    }

    @IBOutlet weak var onePasswordButton: UIButton! {
        didSet {
            onePasswordButton.isHidden = !OnePasswordExtension.shared().isAppExtensionAvailable()
        }
    }

    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var visibleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = serverURL?.host
        AuthManager.recoverAuthIfNeeded()
        
        self.textFieldUsername.text = self.login
        self.textFieldPassword.text = self.password
        
        self.startLoading()
        let authSharedObservable = self.interactor?.checkAuth()?.shareReplay(1)

        _ = authSharedObservable?.filter { value in
                return value == false
            }.flatMap { _ -> Observable<Result<URL>> in
                return  (self.interactor?.validate(URL: self.serverURL))!
            }.flatMap {result -> Observable<Result<AuthSettings>> in
                var result1: Observable<Result<AuthSettings>>?
                switch result {
                case .success(let socketURL):
                    result1 = (self.interactor?.connect(socketURL: socketURL))!
                default:
                    break
                }
                return result1!
            }.subscribe( onNext: {result in
                switch result {
                case .success(let serverSettings):
                    self.serverPublicSettings = serverSettings
                default:
                    break
                }

                self.stopLoading()
            }).disposed(by: disposeBag)

        _ = authSharedObservable?.filter {value in
                return value == true
            }.subscribe( onNext: {_ in
                self.stopLoading()
                self.showChat()
            }).disposed(by: disposeBag)
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

        if !connecting {
            textFieldUsername.becomeFirstResponder()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TwoFactor" {
            if let controller = segue.destination as? TwoFactorAuthenticationViewController {
                controller.username = textFieldUsername.text ?? ""
                controller.password = textFieldPassword.text ?? ""
            }
        }
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

        if response.isError() {
            if let error = response.result["error"].dictionary {
                // User is using 2FA
                if error["error"]?.string == "totp-required" {
                    performSegue(withIdentifier: "TwoFactor", sender: nil)
                    return
                }

                let alert = UIAlertController(
                    title: localized("error.socket.default_error_title"),
                    message: error["message"]?.string ?? localized("error.socket.default_error_message"),
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        } else {
            if let user = AuthManager.currentUser() {
                if user.username != nil {
                    dismiss(animated: true, completion: nil)
                } else {
                    performSegue(withIdentifier: "RequestUsername", sender: nil)
                }
            }
        }
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

        if serverPublicSettings?.isLDAPAuthenticationEnabled ?? false {
            let params = [
                "ldap": true,
                "username": email,
                "ldapPass": password,
                "ldapOptions": []
            ] as [String : Any]

            AuthManager.auth(params: params, completion: self.handleAuthenticationResponse)
        } else {
            AuthManager.auth(email, password: password, completion: self.handleAuthenticationResponse)
        }
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
            authenticateWithUsernameOrEmail()
        }

        return true
    }
}
