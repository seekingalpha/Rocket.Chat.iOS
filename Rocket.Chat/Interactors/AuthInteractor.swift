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

    func checkAuth(complition: @escaping (_ result: Bool) -> Void) {

            if let auth = AuthManager.isAuthenticated() {
                AuthManager.persistAuthInformation(auth)
                AuthManager.resume(auth, completion: { response in
                    guard !response.isError(), !(response is Error) else {
                        complition(false)
                        return
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
                        complition(true)
                    })
                })
            } else {
                complition(false)
            }
    }

     func validate(URL: URL?, complition: @escaping (_ result: Bool, _ socketURL: URL?) -> Void) {

            guard let url = URL else {
                complition(false, nil)
                return
            }
            guard let socketURL = url.socketURL() else {
                complition(false, nil)
                return
            }
            guard let validateURL = url.validateURL() else {
                complition(false, nil)
                return
            }
            let request = URLRequest(url: validateURL)
            let session = URLSession.shared

            let task = session.dataTask(with: request, completionHandler: { (data, _, _) in
                if let data = data {
                    do {
                        let json = try JSON(data: data)
                        Log.debug(json.rawString())
                        guard let version = json["version"].string else {
                            complition(false, nil)
                            return
                        }

                        if let minVersion = Bundle.main.object(forInfoDictionaryKey: "RC_MIN_SERVER_VERSION") as? String {
                            if Semver.lt(version, minVersion) {
                                DispatchQueue.main.async(execute: {
                                    complition(false, nil)
                                })
                            }
                            }
                    } catch {
                    }
                    DispatchQueue.main.async(execute: {
                        complition(true, socketURL)
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        complition(false, nil)
                    })
                }
            })
            task.resume()
    }

    func connect(socketURL: URL!, complition: @escaping (_ sereverSettings: AuthSettings) -> Void, failure: @escaping () -> Void) {
        SocketManager.connect(socketURL) { (_, _) in
            AuthSettingsManager.updatePublicSettings(nil) { (settings) in
                guard let settings = settings else {
                     failure()
                     return
                }
                complition(settings)
            }
        }
    }
}
