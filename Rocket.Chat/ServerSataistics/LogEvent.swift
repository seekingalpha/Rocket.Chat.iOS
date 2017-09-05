//
//  EventDescription.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/4/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class LogEvent: NSObject {
    var user_id: String? = "null"
    var user_agent: String?
    //-
    var machine_ip: String?
    //-
    var machine_cookie: String?
    var url: String?
    //-
    var page_key: String?
    //-
    var url_params: String?
    var refferer: String?
    var refferer_key: String?
}

class PageLoadingLogEvent: LogEvent {
    
}

class ActionLogEvent: LogEvent {
    var type_id: String?
    var source: String?
    var action_id: String?
    var data: String?

}

class ShowLoginPageEvent: PageLoadingLogEvent {
}
