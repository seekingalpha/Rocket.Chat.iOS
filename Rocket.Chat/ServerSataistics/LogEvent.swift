//
//  EventDescription.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/4/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class LogEvent: NSObject {
    var userId: String?
    var userAgent: String?
    //-
    var machineIp: String?
    //-
    var machineCookie: String?
    var url: String?
    //-
    var pageKey: String?
    //-
    var urlParams: String?
    var refferer: String?
    var reffererKey: String?
    override init() {
        super.init()
        self.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_    5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36"
        self.machineIp = "192.168.3.55"
        self.machineCookie = UUID().uuidString
        
    }
}

class ChatPageLogEvent: LogEvent {
    init (subscription: Subscription?) {
        super.init()
        if subscription?.type == .directMessage {
            guard let displayName = subscription?.displayName() else {
                return
            }
            self.url = "/chat/direct_msg/" + displayName
            print(">> direct message")
        } else if subscription?.type == .group {
            self.url = "/chat/group/"
            print(subscription?.displayName() ?? "")
            print(">> group message")
        }
    }
}

class ActionLogEvent: LogEvent {
    var typeId: String?
    var source: String?
    var actionId: String?
    var data: [String: Any]?
}

class ErrorLoginEvent: ActionLogEvent {
    init(login: String?) {
        super.init()
        self.typeId = "credentials"
        self.source = "roadblock"
        self.actionId = "wrong_credentials"
        self.data = ["email": login ?? ""]
    }
}

class SuccessLoginEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "credentials"
        self.source = "roadblock"
        self.actionId = "success"
    }
}

class OpenMenuEvent: ActionLogEvent {
    override init() {
        super.init()
//        Type_id   =   click
//        Source   =   drawer_menu Action_id   =   open
    }
}

class LogoutMenuEvent: ActionLogEvent {
    override init() {
        super.init()
        //        Type_id   =   click
        //        Source   =   drawer_menu Action_id   =   open
    }
}

class DirectMessageEvent: ActionLogEvent {
    override init() {
        super.init()
        //        Type_id   =   click
        //        Source   =   drawer_menu Action_id   =   open
    }
}

class GroupMessageEvent: ActionLogEvent {
    init(data: [String: Any]) {
        super.init()
        //        Type_id   =   click
        //        Source   =   drawer_menu Action_id   =   open
    }
}

