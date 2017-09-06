//
//  LogEventToPostParamsConvertor.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/6/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class EventConverter {
//    init(event: ActionLogEvent) {
//        
//    }
//    init(event: LogEvent) {
//        
//    }
    func convertToPost(event: ActionLogEvent?) -> Data? {
       return nil
    }
    func convertToPost(event: LogEvent?) -> Data? {
       
        let params = ["user_id": event?.userId ?? "null",
                      "user_agent": event?.userAgent ?? "null",
                      "machine_ip": event?.machineIp ?? "null",
                      "machine_cookie": event?.machineCookie ?? "null",
                      "page_key": event?.pageKey ?? "null",
                      "refferer": event?.refferer ?? "null",
                      "refferer_key": event?.reffererKey ?? "null",
                      "url": event?.url ?? "null"]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return nil
        }
        return httpBody
    }
}
