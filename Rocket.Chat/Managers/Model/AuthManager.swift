//
//  AuthManager.swift
//  Rocket.Chat
//
//  Created by Rafael K. Streit on 7/8/16.
//  Copyright © 2016 Rocket.Chat. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

struct AuthManager {

    /**
        - returns: Last auth object (sorted by lastAccess), if exists.
    */
    static func isAuthenticated() -> Auth? {
        guard let realm = Realm.shared else { return nil }
        return realm.objects(Auth.self).sorted(byKeyPath: "lastAccess", ascending: false).first
    }

    /**
        - returns: Current user object, if exists.
    */
    static func currentUser() -> User? {
        guard let realm = Realm.shared else { return nil }
        guard let auth = isAuthenticated() else { return nil }
        return realm.object(ofType: User.self, forPrimaryKey: auth.userId)
    }

    /**
        This method is going to persist the authentication informations
        that was latest used in NSUserDefaults to keep it safe if something
        goes wrong on database migration.
     */
    static func persistAuthInformation(_ auth: Auth) {
        let defaults = UserDefaults.standard
        let selectedIndex = DatabaseManager.selectedIndex

        guard
            let token = auth.token,
            let userId = auth.userId,
            var servers = DatabaseManager.servers,
            servers.count > selectedIndex
        else {
            return
        }

        servers[selectedIndex][ServerPersistKeys.token] = token
        servers[selectedIndex][ServerPersistKeys.userId] = userId

        defaults.set(servers, forKey: ServerPersistKeys.servers)
    }

    static func selectedServerInformation(index: Int? = nil) -> [String: String]? {
        guard
            let servers = DatabaseManager.servers,
            servers.count > 0
        else {
            return nil
        }

        var server: [String: String]?
        if let index = index {
            server = servers[index]
        } else {
            server = servers[DatabaseManager.selectedIndex]
        }

        return server
    }

    /**
        This method migrates the old authentication storaged format
        to a new one that supports multiple authentication at the
        same app installation.
     
        Last version using the old format: 1.2.1.
     */
    static func recoverOldAuthFormatIfNeeded() {
        if AuthManager.isAuthenticated() != nil {
            return
        }

        let defaults = UserDefaults.standard

        guard
            let token = defaults.string(forKey: ServerPersistKeys.token),
            let serverURL = defaults.string(forKey: ServerPersistKeys.serverURL),
            let userId = defaults.string(forKey: ServerPersistKeys.userId) else {
                return
        }

        let servers = [[
            ServerPersistKeys.databaseName: "\(String.random()).realm",
            ServerPersistKeys.token: token,
            ServerPersistKeys.serverURL: serverURL,
            ServerPersistKeys.userId: userId
        ]]

        defaults.set(0, forKey: ServerPersistKeys.selectedIndex)
        defaults.set(servers, forKey: ServerPersistKeys.servers)
        defaults.removeObject(forKey: ServerPersistKeys.token)
        defaults.removeObject(forKey: ServerPersistKeys.serverURL)
        defaults.removeObject(forKey: ServerPersistKeys.userId)
    }

    /**
        Recovers the authentication on database if needed
     */
    static func recoverAuthIfNeeded() {
        if AuthManager.isAuthenticated() != nil {
            return
        }

        recoverOldAuthFormatIfNeeded()

        guard
            let server = selectedServerInformation(),
            let token = server[ServerPersistKeys.token],
            let serverURL = server[ServerPersistKeys.serverURL],
            let userId = server[ServerPersistKeys.userId]
        else {
            return
        }

        DatabaseManager.changeDatabaseInstance()

        Realm.executeOnMainThread({ (realm) in
            // Clear database
            realm.deleteAll()

            let auth = Auth()
            auth.lastSubscriptionFetch = nil
            auth.lastAccess = Date()
            auth.serverURL = serverURL
            auth.token = token
            auth.userId = userId

            PushManager.updatePushToken()

            realm.add(auth)
        })
    }
}

// MARK: Socket Management

extension AuthManager {

    /**
        This method resumes a previous authentication with token
        stored in the Realm object.
 
        - parameter auth The Auth object that user wants to resume.
        - parameter completion The completion callback that will be
            called in case of success or error.
    */
    static func resume(_ auth: Auth, completion: @escaping MessageCompletion) {
        guard let url = URL(string: auth.serverURL) else { return }
        guard let apiHost = auth.apiHost else { return }

        API.shared.host = apiHost
        API.shared.authToken = auth.token
        API.shared.userId = auth.userId

        SocketManager.connect(url) { (socket, _) in
            guard SocketManager.isConnected() else {
                guard let response = SocketResponse(
                    ["error": "Can't connect to the socket"],
                    socket: socket
                ) else { return }

                return completion(response)
            }

            let object = [
                "msg": "method",
                "method": "login",
                "params": [[
                    "resume": auth.token ?? ""
                ]]
            ] as [String: Any]

            SocketManager.send(object) { (response) in
                guard !response.isError() else {
                    completion(response)
                    return
                }

                PushManager.updatePushToken()
                completion(response)
            }
        }
    }

    /**
        Method that creates an User account.
     */
    static func signup(with name: String, _ email: String, _ password: String, completion: @escaping MessageCompletion) {
//        let object = [
//            "msg": "method",
//            "method": "registerUser",
//            "params": [[
//                "email": email,
//                "pass": password,
//                "name": name
//            ]]
//        ] as [String : Any]
//
//        SocketManager.send(object) { (response) in
//            guard !response.isError() else {
//                completion(response)
//                return
//            }
//            let params = [
//                            "email": email,
//                            "password": password
//                        ]
//            self.auth(params: params, completion: completion)
//        }
    }

    /**
        Generic method that authenticates the user.
    */
    static func auth(urlSession: URLSession, params: [String: Any], completion: @escaping HTTPComplition, websocketURL: String, servereAuthURL: String) {
        self.post(session: urlSession, params : params, url : servereAuthURL, complition : { result in
            
            var httpResponse = HTTPResponse()
            guard let response = result as? [String: Any] else {
                return
            }
            
            guard let rc_token = result?["rc_token"] as? String else {
                httpResponse.isError = true
                httpResponse.response = response
                completion(httpResponse)
                return
            }
            guard let user_id = result?["user_id"] as? String else {
                httpResponse.isError = true
                completion(httpResponse)
                return
            }
            
            Realm.execute({ (realm) in
                // Delete all the Auth objects, since we don't
                // support multiple-server authentication yet
                realm.delete(realm.objects(Auth.self))
                
                let auth = Auth()
                auth.lastSubscriptionFetch = nil
                auth.lastAccess = Date()
                auth.serverURL = websocketURL
                auth.token = rc_token
                auth.userId = user_id
                PushManager.updatePushToken()
                
                realm.add(auth)
            }, completion: {
                completion(httpResponse)
            })
        })
    }

    static func auth(params: [String: Any], completion: @escaping MessageCompletion) {
        let object = [
            "msg": "method",
            "method": "login",
            "params": [params]
        ] as [String: Any]

        SocketManager.send(object) { (response) in
            guard !response.isError() else {
                completion(response)
                return
            }

            let result = response.result

            let auth = Auth()
            auth.lastSubscriptionFetch = nil
            auth.lastAccess = Date()
            auth.serverURL = response.socket?.currentURL.absoluteString ?? ""
            auth.token = result["result"]["token"].string
            auth.userId = result["result"]["id"].string

            API.shared.authToken = auth.token
            API.shared.userId = auth.userId

            if let date = result["result"]["tokenExpires"]["$date"].double {
                auth.tokenExpires = Date.dateFromInterval(date)
            }

            persistAuthInformation(auth)
            DatabaseManager.changeDatabaseInstance()

            Realm.executeOnMainThread({ (realm) in
                // Delete all the Auth objects, since we don't
                // support multiple-server per database
                realm.delete(realm.objects(Auth.self))

                PushManager.updatePushToken()
                realm.add(auth)
            })

            ServerManager.timestampSync()
            completion(response)
        }
    }

    /**
        This method authenticates the user with email and password.
 
        - parameter username: Username
        - parameter password: Password
        - parameter completion: The completion block that'll be called in case
            of success or error.
    */
//    static func auth(_ username: String, password: String, code: String? = nil, completion: @escaping MessageCompletion) {
//        let usernameType = username.contains("@") ? "email" : "username"
//        var params: [String: Any]?
//
//        if let code = code {
//            params = [
//                "totp": [
//                    "login": [
//                        "user": [usernameType: username],
//                        "password": [
//                            "digest": password.sha256(),
//                            "algorithm": "sha-256"
//                        ]
//                    ],
//                    "code": code
//                ]
//            ]
//        } else {
//            params = [
//                "email": username,
//                "password": password
//            ]
//        }
//
//        if let params = params {
//            self.auth(params: params, completion: completion)
//        }
//    }

    /**
        This method authenticates the user with a credential token
        and a credential secret (retrieved via an OAuth method)

        - parameter token: The credential token
        - parameter secret: The credential secret
        - parameter completion: The completion block that'll be called in case
            of success or error.
     */
    static func auth(credentials: OAuthCredentials, completion: @escaping MessageCompletion) {
        let params = [
            "oauth": [
                "credentialToken": credentials.token,
                "credentialSecret": credentials.secret
            ] as [String: Any]
        ]

        AuthManager.auth(params: params, completion: completion)
    }

    /**
        Returns the username suggestion for the logged in user.
    */
    static func usernameSuggestion(completion: @escaping MessageCompletion) {
        let object = [
            "msg": "method",
            "method": "getUsernameSuggestion"
        ] as [String: Any]

        SocketManager.send(object, completion: completion)
    }

    /**
     Set username of logged in user
     */
    static func setUsername(_ username: String, completion: @escaping MessageCompletion) {
        let object = [
            "msg": "method",
            "method": "setUsername",
            "params": [username]
        ] as [String: Any]

        SocketManager.send(object, completion: completion)
    }

    /**
        Logouts user from the app, clear database
        and disconnects from the socket.
     */
    static func logout(completion: @escaping VoidCompletion) {
        SocketManager.disconnect { (_, _) in
            GIDSignIn.sharedInstance().signOut()

            DraftMessageManager.clearServerDraftMessages()
            DatabaseManager.removerSelectedDatabase()

            Realm.executeOnMainThread({ (realm) in
                realm.deleteAll()
            })

            completion()
        }
    }

/*    static func updatePublicSettings(_ auth: Auth?, completion: @escaping MessageCompletionObject<AuthSettings?>) {
        let object = [
            "msg": "method",
            "method": "public-settings/get"
        ] as [String : Any]

        SocketManager.send(object) { (response) in
            guard !response.isError() else {
                completion(nil)
                return
            }

            Realm.executeOnMainThread({ realm in
                let settings = AuthManager.isAuthenticated()?.settings ?? AuthSettings()
                settings.map(response.result["result"], realm: realm)
                realm.add(settings, update: true)

                if let auth = AuthManager.isAuthenticated() {
                    auth.settings = settings
                    realm.add(auth, update: true)
                }

                let unmanagedSettings = AuthSettings(value: settings)
                completion(unmanagedSettings)
            })
        }
    }
*/

    static func post(session: URLSession, params: [String: Any], url: String, complition: @escaping (_ result: NSDictionary?) -> Void ) {

        guard let serviceUrl = URL(string: url) else { return }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic c2Vla2luZ2FscGhhOmlwdmlwdg==", forHTTPHeaderField: "Authorization")
        request.addValue("gzip, deflate, sdch", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_    5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.addValue("1", forHTTPHeaderField: "Fastly-Debug")

        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return
        }
        request.httpBody = httpBody

        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)

                    if let dict = json as? NSDictionary {
                        DispatchQueue.main.async {
                            complition(dict)
                        }
                    }
                } catch {
                    print(error)
                }
            }
            }.resume()
    }
}
