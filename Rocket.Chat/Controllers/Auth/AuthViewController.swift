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
import RealmSwift

@objc final class AuthViewController: ConnectServerViewController, URLSessionDelegate {
    @objc var login: String?
    @objc var password: String?

    @objc var websocketURL: String?
    @objc var servereAuthURL: String?
    var loginServicesToken: NotificationToken?
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var onePasswordButton: UIButton! {
        didSet {
            onePasswordButton.isHidden = !OnePasswordExtension.shared().isAppExtensionAvailable()
        }
    }

    @IBOutlet weak var textFieldUsername: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
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

    @IBOutlet var buttonRegister: UIButton!

    @IBOutlet weak var authButtonsStackView: UIStackView!
    var customAuthButtons = [String: UIButton]()

    deinit {
        loginServicesToken?.invalidate()
        NotificationCenter.default.removeObserver(self)
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

        //if let registrationForm = AuthSettingsManager.shared.settings?.registrationForm {
         //  buttonRegister.isHidden = registrationForm != .isPublic
        //}
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupLoginServices()

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
        if response.isError() {
            stopLoading()

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
            
            return
        }
        
        API.shared.fetch(MeRequest()) { [weak self] result in
            self?.stopLoading()
            if let user = result?.user {
                if user.username != nil {
                    
                    DispatchQueue.main.async {
                        self?.dismiss(animated: true, completion: nil)
                        
                        let storyboardChat = UIStoryboard(name: "Main", bundle: Bundle.main)
                        let controller = storyboardChat.instantiateInitialViewController()
                        let application = UIApplication.shared
                        
                        if let window = application.windows.first {
                            window.rootViewController = controller
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.performSegue(withIdentifier: "RequestUsername", sender: nil)
                    }
                }
            }
        }
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
        DispatchQueue.main.async(execute: {
            self.textFieldUsername.alpha = 1
            self.textFieldPassword.alpha = 1
            self.activityIndicator.stopAnimating()
        })

        connecting = false
    }

    // MARK: IBAction
    func authenticateWithUsernameOrEmail() {
        let email = textFieldUsername.text ?? ""
        let password = textFieldPassword.text ?? ""
        startLoading()
        let params = ["email": email,
                      "password": password]
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        AuthManager.auth(urlSession:urlSession, params: params, httpCompletion: self.loginResponse, websocketURL: self.websocketURL!, servereAuthURL: self.servereAuthURL!)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {        completionHandler(            .useCredential,            URLCredential(trust: challenge.protectionSpace.serverTrust!)        )
    }
    @IBAction func buttonAuthenticateGoogleDidPressed(_ sender: Any) {
        authenticateWithGoogle()
    }

    @IBAction func buttonTermsDidPressed(_ sender: Any) {
//        var components = URLComponents()
//        components.scheme = "https"
//        components.host = self.serverURL?.host
//
//        if var newURL = components.url {
//            newURL = newURL.appendingPathComponent("terms-of-service")
//
//            let controller = SFSafariViewController(url: newURL)
//            present(controller, animated: true, completion: nil)
//        }
    }

    @IBAction func buttonPolicyDidPressed(_ sender: Any) {
//        var components = URLComponents()
//        components.scheme = "https"
//        components.host = self.serverURL?.host
//
//        if var newURL = components.url {
//            newURL = newURL.appendingPathComponent("privacy-policy")
//
//            let controller = SFSafariViewController(url: newURL)
//            present(controller, animated: true, completion: nil)
//        }
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
    func showMainViewController() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
            
            let storyboardChat = UIStoryboard(name: "Main", bundle: Bundle.main)
            let controller = storyboardChat.instantiateInitialViewController()
            let application = UIApplication.shared
            
            if let window = application.windows.first {
                window.rootViewController = controller
            }
        }
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

// MARK: Login Services

extension AuthViewController {
    func setupLoginServices() {
        self.loginServicesToken?.invalidate()

        self.loginServicesToken = LoginServiceManager.observe { [weak self] changes in
            self?.updateLoginServices(changes: changes)
        }

        LoginServiceManager.subscribe()
    }

    @objc func loginServiceButtonDidPress(_ button: UIButton) {
//        guard let service = customAuthButtons.filter({ $0.value == button }).keys.first,
//              let realm = Realm.shared,
//              let loginService = LoginService.find(service: service, realm: realm)
//        else {
//            return
//        }
//
//        OAuthManager.authorize(loginService: loginService, at: serverURL, viewController: self,
//                               success: { [weak self] credentials in
//
//            guard let strongSelf = self else { return }
//            AuthManager.auth(credentials: credentials, completion: strongSelf.handleAuthenticationResponse)
//
//        }, failure: { [weak self] in
//
//            self?.alert(title: localized("alert.login_service_error.title"),
//                        message: localized("alert.login_service_error.title"))
//
//        })
    }

    func updateLoginServices(changes: RealmCollectionChange<Results<LoginService>>) {
        switch changes {
        case .update(let res, let deletions, let insertions, let modifications):
            insertions.map { res[$0] }.forEach {
                guard $0.custom, !($0.serverURL?.isEmpty ?? true) else { return }

                let button = UIButton()
                button.layer.cornerRadius = 3
                button.setTitle($0.buttonLabelText ?? "", for: .normal)
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
                button.setTitleColor(UIColor(hex: $0.buttonLabelColor), for: .normal)
                button.backgroundColor = UIColor(hex: $0.buttonColor)
                button.addTarget(self, action: #selector(loginServiceButtonDidPress(_:)), for: .touchUpInside)

                authButtonsStackView.addArrangedSubview(button)

                customAuthButtons[$0.service ?? ""] = button
            }

            modifications.map { res[$0] }.forEach {
                guard $0.custom,
                      let identifier = $0.identifier,
                      let button = self.customAuthButtons[identifier]
                else {
                    return
                }

                button.setTitle($0.buttonLabelText ?? "", for: .normal)
                button.setTitleColor(UIColor(hex: $0.buttonLabelColor), for: .normal)
                button.backgroundColor = UIColor(hex: $0.buttonColor)
            }

            deletions.map { res[$0] }.forEach {
                guard $0.custom,
                      let identifier = $0.identifier,
                      let button = self.customAuthButtons[identifier]
                else {
                    return
                }

                authButtonsStackView.removeArrangedSubview(button)
                customAuthButtons.removeValue(forKey: identifier)
            }
        default:
            break
        }
    }
}
