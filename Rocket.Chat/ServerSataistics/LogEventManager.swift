//
//  LogEventManager.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/5/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class LogEventManager: NSObject, URLSessionDelegate {
    var httpSessionManager: LogEventManager?
    var latestPageKey: String? = nil

    func send(event: LogEvent?) {
        if event?.pageKey != nil {
            self.latestPageKey = event?.pageKey
        }
        let httpBody = event?.convertToPost(previousPageKey: latestPageKey)
        self.post(httpBody: httpBody, url: event?.moneURL)
    }
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        completionHandler(
            .useCredential,
            URLCredential(trust: challenge.protectionSpace.serverTrust!)
        )
    }
    func post(httpBody: Data?, url: String?) {

        guard let httpBody = httpBody else {
            return
        }
        guard let url = url else {
            return
        }
        guard let serviceUrl = URL(string: url) else {
            return
        }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.addValue("Basic c2Vla2luZ2FscGhhOmlwdmlwdg==", forHTTPHeaderField: "Authorization")
        request.setValue("com.seekingalpha.chat.iOS Mozilla/5.0 (Macintosh Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.httpBody = httpBody

        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(">>>>>>> event sending response ")
                print(response)
            }
            if let data = data {
                let datastring = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                 print(datastring)
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
//                    if let dict = json as? NSDictionary {
//                        complition(dict)
//                    }
                } catch {
                    print(error)
                }
            }
            }.resume()
    }
}
