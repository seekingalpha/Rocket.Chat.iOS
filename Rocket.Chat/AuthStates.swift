//
//  AuthStates.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 7/26/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class AuthState: NSObject {
    @objc var authViewController: AuthViewController!
    @objc var nextSuccess: AuthState?
    @objc var nextFailure: AuthState?
    @objc var nextFailureWithConnectionError: AuthState?
    @objc init(authViewController: AuthViewController) {
        self.authViewController = authViewController
    }
    override init() {

    }
    func execute() {
    }
    @objc var logEventManager: LogEventManager?
    @objc var logEvent: LogEvent?
}

class FirstLoadingState: AuthState {

    override func execute() {
//        print(self.authViewController)
        authViewController.contentContainer.isHidden = true
        authViewController.customActivityIndicator.startAnimating()
        authViewController.textFieldUsername.resignFirstResponder()
        authViewController.textFieldPassword.resignFirstResponder()
        
//        authViewController.interactor?.checkAuth(complition: { [unowned self] result in
//            if result == false {
//                let url = self.authViewController.serverURL
//                self.authViewController.interactor?.validate(URL1: url, complition: { (isValid, socketURL) in
//                    if isValid && socketURL != nil {
//                        self.authViewController.interactor?.connect(socketURL: socketURL, complition: { (serverSettings) in
//                            self.authViewController.serverPublicSettings = serverSettings
//                            self.authViewController.finishExecution(nextState: self.nextFailure)
//                        }, failure: {
//                            self.authViewController.finishExecution(nextState: self.nextFailureWithConnectionError)
//                        })
//                    } else {
//                        self.authViewController.finishExecution(nextState: self.nextFailureWithConnectionError)
//                    }
//                })
//            } else {
//                self.authViewController.finishExecution(nextState: self.nextSuccess)
//            }
//        })
        /*
         ail {
         self.authViewController.finishExecution(nextState: self.nextFailureWithConnectionError)
         }
         */
        
        authViewController.connect(success: { isUserLoggedIn in
            if isUserLoggedIn {
                self.authViewController.finishExecution(nextState: self.nextSuccess)
            } else {
                 self.authViewController.finishExecution(nextState: self.nextFailure)
            }
        }, fail: {
             self.authViewController.finishExecution(nextState: self.nextFailureWithConnectionError)
        })
    }
        /*
         ) {
         self.authViewController.finishExecution(nextState: self.nextFailureWithConnectionError)
         }
         }
         */
}

class ShowLoginState: AuthState {
    override func execute() {
        self.authViewController.contentContainer.isHidden = false
        self.authViewController.customActivityIndicator.stopAnimating()
        self.authViewController.textFieldUsername.becomeFirstResponder()
    }
}

class ShowMainState: AuthState {
    override func execute() {
        self.authViewController.contentContainer.isHidden = false
        self.authViewController.customActivityIndicator.stopAnimating()
        self.authViewController.showMainViewController()
        self.authViewController.finishExecution(nextState: nil)
    }
}

class LoginInProgressState: AuthState {
    override func execute() {
        self.authViewController.authenticateWithUsernameOrEmail()
    }
}

class LoginSuccessState: AuthState {
    override func execute() {
        self.authViewController.startLoading()
        AuthManager.currentUser()?.setEmail(email: self.authViewController.textFieldUsername.text)
        let logEvent = SuccessLoginEvent(login: AuthManager.currentUser()?.email())
        self.logEventManager?.send(event: logEvent)
        self.authViewController.showMainViewController()
    }
}

class LoginFailureState: AuthState {
    override func execute() {
        let text = self.authViewController.textFieldUsername.text
        let event = ErrorLoginEvent(login: text)
        self.logEventManager?.send(event: event)
        self.authViewController.finishExecution(nextState: nil)
    }
}

class AuthStateMachine: NSObject {
    @objc var currentState: AuthState?
    @objc var rootState: AuthState?

    func switchState(state: AuthState) {
        self.currentState = state
    }
    func execute() {
        self.currentState?.execute()
    }
    func success() {
        guard let transitinableState = self.currentState else {
            return
        }
        self.currentState = transitinableState.nextSuccess
        self.execute()
    }
    func error() {
        guard let transitinableState = self.currentState else {
            return
        }
        self.currentState = transitinableState.nextFailure
        self.execute()
    }
}

class ValidationConnectionError: AuthState {
    override func execute() {
        self.authViewController.stopLoading()
        self.authViewController.contentContainer.isHidden = false
        self.authViewController.customActivityIndicator.stopAnimating()

        let alertController = UIAlertController(title: "Connection Error", message: "Unable to connect with the server. Check you connection and try again.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Try again", style: .default) {[weak self] (_) in
            self?.authViewController.finishExecution(nextState: self?.nextSuccess)
        }
        alertController.addAction(action)
        self.authViewController.present(alertController, animated: true)
    }
}
