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
@objc final class AuthViewController: BaseViewController, URLSessionDelegate {
    @objc var interactor: AuthInteractor?
    internal var connecting = false
    @objc var serverURL: URL?
    @objc var serverPublicSettings: AuthSettings?
    @objc var login: String?
    @objc var password: String?
    @objc var stateMachine: AuthStateMachine?
    @objc var logEventManager: LogEventManager?
    @objc var logEvent: LogEvent?

    @objc var websocketURL: String?
    @objc var servereAuthURL: String?

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
        self.stateMachine?.execute()
        self.logEventManager?.send(event: self.logEvent)
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
        self.stateMachine?.success()
    }

    internal func loginResponse(_ response: HTTPResponse) {
        stopLoading()
        if !response.isError {
            self.stateMachine?.success()
        } else {
            if let error = response.response?["error"] as? [String: Any] {
                if let errorCode = error["code"] as? NSInteger {
                    if errorCode == 3 {
                        self.performSegue(withIdentifier: "403", sender: nil)
                    } else if let message = error["msg"] as? String {
                        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
            self.stateMachine?.error()
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
        let params = ["email": email,
                      "password": password]
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        AuthManager.auth(urlSession:urlSession, params: params, completion: self.loginResponse, websocketURL: self.websocketURL!, servereAuthURL: self.servereAuthURL!)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {        completionHandler(            .useCredential,            URLCredential(trust: challenge.protectionSpace.serverTrust!)        )
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
        guard let nextState = nextState else {
            return
        }
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
