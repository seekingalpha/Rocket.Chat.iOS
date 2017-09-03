//
//  AuthInteractor.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 7/24/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import semver

public enum ErrorType {
    case invalidURL
    case wrongServerVersion(version: String, minVersion: String)
    case connectionError
}

public enum Result<Value> {
    case success(Value)
    case failure(ErrorType)
}

class AuthInteractor: NSObject {

    func checkAuth() -> Observable<Bool>? {

        return Observable.create { observer in
            if let auth = AuthManager.isAuthenticated() {
                AuthManager.persistAuthInformation(auth)
                AuthManager.resume(auth, completion: { response in
                    guard !response.isError(), response is Error else {
                        return observer.onNext(false)
                    }
                    SubscriptionManager.updateSubscriptions(auth, completion: { _ in
                        AuthSettingsManager.updatePublicSettings(auth, completion: { _ in
                        })

                        UserManager.userDataChanges()
                        UserManager.changes()
                        SubscriptionManager.changes(auth)

                        if let userIdentifier = auth.userId {
                            PushManager.updateUser(userIdentifier)
                        }
                        observer.onNext(true)
                    })
                })
            } else {
                observer.onNext(false)
            }
            return Disposables.create()
        }
    }

    func validate(URL: URL?) -> Observable<Result<URL>>? {
        return Observable.create { observer in
            guard let url = URL else {
                observer.onNext(Result.failure(.invalidURL))
                return Disposables.create()
            }
            guard let socketURL = url.socketURL() else {
                observer.onNext(Result.failure(.invalidURL))
                return Disposables.create()
            }
            guard let validateURL = url.validateURL() else {
                observer.onNext(Result.failure(.invalidURL))
                return Disposables.create()
            }
            let request = URLRequest(url: validateURL)
            let session = URLSession.shared

            let task = session.dataTask(with: request, completionHandler: { (data, _, _) in
                if let data = data {
                    let json = JSON(data: data)
                    Log.debug(json.rawString())

                    guard let version = json["version"].string else {
                        return observer.onNext(Result.failure(.invalidURL))
                    }

                    if let minVersion = Bundle.main.object(forInfoDictionaryKey: "RC_MIN_SERVER_VERSION") as? String {
                        if Semver.lt(version, minVersion) {
                            DispatchQueue.main.async(execute: {
                                observer.onNext(Result.failure(ErrorType.wrongServerVersion(version: version, minVersion: minVersion)))
                                observer.onCompleted()
                            })
                        }
                    }
                    DispatchQueue.main.async(execute: {
                        observer.onNext(Result.success(socketURL))
                        observer.onCompleted()
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        observer.onNext(Result.failure(.invalidURL))
                        observer.onCompleted()
                    })
                }
            })

            task.resume()
            return Disposables.create {
                task.cancel()
            }
        }
    }

    func connect(socketURL: URL!) -> Observable<Result<AuthSettings>>? {
        return Observable.create { observer in

            SocketManager.connect(socketURL) { (_, _) in
                AuthSettingsManager.updatePublicSettings(nil) { (settings) in
                    guard let settings = settings else {
                         observer.onNext(.failure(.connectionError))
                         observer.onCompleted()
                         return
                    }
                    observer.onNext(Result.success(settings))
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
