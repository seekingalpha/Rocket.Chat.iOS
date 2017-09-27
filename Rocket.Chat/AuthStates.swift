//
//  AuthStates.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 7/26/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class AuthState: NSObject {
    var authViewController: AuthViewController!
    var nextSuccess: AuthState?
    var nextFailure: AuthState?
    init(authViewController: AuthViewController) {
        self.authViewController = authViewController
    }
    override init() {

    }
    func execute() {
    }
    var logEventManager: LogEventManager?
    var logEvent: LogEvent?
}

class FirstLoadingState: AuthState {

    let disposeBag = DisposeBag()
    override func execute() {
        print(self.authViewController)
        self.authViewController.contentContainer.isHidden = true
        self.authViewController.customActivityIndicator.startAnimating()
        self.authViewController.textFieldUsername.resignFirstResponder()
        self.authViewController.textFieldPassword.resignFirstResponder()

        let authSharedObservable = self.authViewController.interactor?.checkAuth()?.shareReplay(1)
        _ = authSharedObservable?.filter { value in
            return value == false
            }.flatMap { _ -> Observable<Result<URL>> in
                return  (self.authViewController.interactor?.validate(URL: self.authViewController.serverURL))!
            }.flatMap {result -> Observable<Result<AuthSettings>> in
                var result1: Observable<Result<AuthSettings>>?
                switch result {
                case .success(let socketURL):
                    result1 = (self.authViewController.interactor?.connect(socketURL: socketURL))!
                default:
                    break
                }
                return result1!
            }.subscribe( onNext: {result in
                switch result {
                case .success(let serverSettings):
                    self.authViewController.serverPublicSettings = serverSettings
                    self.authViewController.finishExecution(nextState: self.nextFailure)
                default:
                    break
                }
            }).disposed(by: disposeBag)

        _ = authSharedObservable?.filter {value in
            return value == true
            }.subscribe( onNext: {_ in
                self.authViewController.finishExecution(nextState: self.nextSuccess)
            }).disposed(by: disposeBag)
    }
}

class ShowLoginState: AuthState {
    override func execute() {
        self.authViewController.contentContainer.isHidden = false
        self.authViewController.customActivityIndicator.stopAnimating()
        self.authViewController.textFieldUsername.becomeFirstResponder()
        self.logEventManager?.send(event:self.logEvent)
    }
}

class ShowChatState: AuthState {
    override func execute() {
        self.authViewController.contentContainer.isHidden = false
        self.authViewController.customActivityIndicator.stopAnimating()
        self.authViewController.showChat()
        self.authViewController.finishExecution(nextState: nil)
    }
}

class LoginInProgressState: AuthState {
    override func execute() {
        self.authViewController.authenticateWithUsernameOrEmail()
    }
}

class LoginSuccessState: AuthState {
    let disposeBag = DisposeBag()
    override func execute() {
        self.authViewController.startLoading()
        _ = self.authViewController.interactor?.checkAuth()?.filter {value in
            return value == true
            }.subscribe( onNext: {_ in
                if let user = AuthManager.currentUser() {
                    if user.username != nil {
                        self.authViewController.stopLoading()
                        user.setEmail(email: self.authViewController.login)
                        let logEvent = SuccessLoginEvent(login: user.email())
                        self.logEventManager?.send(event: logEvent)
                        self.authViewController.showChat()
                    }
                }
            }).disposed(by: disposeBag)
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
    var currentState: AuthState?
    var rootState: AuthState?

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
