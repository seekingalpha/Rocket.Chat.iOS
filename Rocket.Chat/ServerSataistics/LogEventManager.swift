//
//  LogEventManager.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/5/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class LogEventManager: NSObject {
    var eventConverter = EventConverter()

    func send(event: LogEvent?) {
        
        guard let path = event?.url else {
            return
        }

        var url: String?
        if let params = event?.urlParams {
            url = path + params
        } else {
            url = path
        }

        let httpBody = eventConverter.convertToPost(event: event)
        self.post(httpBody: httpBody, url: url) { result in
        }
    }
    
    func post(httpBody: Data?, url: String?, complition: @escaping (_ result: NSDictionary?) -> Void ) {
        guard let url = url else {
            return
        }
        guard let httpBody = httpBody else {
            return
        }
        let serviceUrl = URL(string: "https://staging.seekingalpha.com/mone_event")
        var request = URLRequest(url: serviceUrl!)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic c2Vla2luZ2FscGhhOmlwdmlwdg==", forHTTPHeaderField: "Authorization")
        request.addValue("gzip, deflate, sdch", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_    5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.addValue("1", forHTTPHeaderField: "Fastly-Debug")
        request.httpBody = httpBody

        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)

                    if let dict = json as? NSDictionary {
                        complition(dict)
                    }
                } catch {
                    print(error)
                }
            }
            }.resume()
    }

}
