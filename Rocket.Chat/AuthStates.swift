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

protocol AuthState {
    var authViewController: AuthViewController { get set }
    init(authViewController: AuthViewController)
    func execute()
}

protocol TransitionState {
    func success() -> AuthState?
    func failure() -> AuthState?
}

struct FirstLoadingState: AuthState {
    var authViewController: AuthViewController
    init(authViewController: AuthViewController) {
        self.authViewController = authViewController
    }
    let disposeBag = DisposeBag()
    func execute() {
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
                    self.authViewController.finishExecution(nextState: ShowLoginState(authViewController: self.authViewController))
                default:
                    break
                }
            }).disposed(by: disposeBag)

        _ = authSharedObservable?.filter {value in
            return value == true
            }.subscribe( onNext: {_ in
                self.authViewController.finishExecution(nextState: ShowChatState(authViewController: self.authViewController))
            }).disposed(by: disposeBag)
    }
}

struct ShowLoginState: AuthState, TransitionState {
    var authViewController: AuthViewController
    init(authViewController: AuthViewController) {
        self.authViewController = authViewController
    }
    func execute() {
        self.authViewController.contentContainer.isHidden = false
        self.authViewController.customActivityIndicator.stopAnimating()
        self.authViewController.textFieldUsername.becomeFirstResponder()
    }
    func success() -> AuthState? {
        return LoginInProgressState(authViewController: self.authViewController)
    }
    func failure() -> AuthState? {
        return nil
    }

}

struct ShowChatState: AuthState {
    var authViewController: AuthViewController
    init(authViewController: AuthViewController) {
        self.authViewController = authViewController
    }
    func execute() {
        self.authViewController.contentContainer.isHidden = false
        self.authViewController.customActivityIndicator.stopAnimating()
        self.authViewController.showChat()
        self.authViewController.finishExecution(nextState: nil)
    }
}

struct LoginInProgressState: AuthState, TransitionState {
    var authViewController: AuthViewController
    init(authViewController: AuthViewController) {
        self.authViewController = authViewController
    }
    func execute() {
        self.authViewController.authenticateWithUsernameOrEmail()
    }
    func success() -> AuthState? {
        return LoginSuccessState(authViewController: self.authViewController)
    }
    func failure() -> AuthState? {
        return nil
    }
}

struct LoginSuccessState: AuthState {
    var authViewController: AuthViewController
    init(authViewController: AuthViewController) {
        self.authViewController = authViewController
    }
    let disposeBag = DisposeBag()
    func execute() {
        self.authViewController.startLoading()
        _ = self.authViewController.interactor?.checkAuth()?.filter {value in
            return value == true
            }.subscribe( onNext: {_ in
                if let user = AuthManager.currentUser() {
                    if user.username != nil {
                        self.authViewController.stopLoading()
                        self.authViewController.showChat()
                    }
                }
            }).disposed(by: disposeBag)
    }
}

class AuthStateMachine: NSObject {
    private var currentState: AuthState?
    func switchState(state: AuthState?) {
        self.currentState = state
    }
    func execute() {
        self.currentState?.execute()
    }
    func success() {
        guard let transitinableState = self.currentState as? TransitionState else {
            return
        }
        self.currentState = transitinableState.success()
        self.execute()
    }
}
