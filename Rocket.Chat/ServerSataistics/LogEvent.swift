//
//  EventDescription.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/4/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class LogEvent: NSObject {
    var userId: String? {
        get {
            return AuthManager.currentUser()?.identifier ?? "null"
        }
    }
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
    override init() {
        super.init()
        self.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_    5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36"
        self.machineCookie = UUID().uuidString
        self.machineIp = IPaddress.getIPAddress()
    }
    func convertToPost() -> Data? {

        let params = ["user_id": self.userId ?? "null",
                      "user_agent": self.userAgent ?? "null",
                      "machine_ip": self.machineIp ?? "null",
                      "machine_cookie": self.machineCookie ?? "null",
                      "page_key": self.pageKey ?? "null",
                      "url": self.url ?? "null"]

        print(">>>>>>>> event params: ")
        print(params)

        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return nil
        }
        return httpBody
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
        } else if subscription?.type == .group {
            self.url = "/chat/group/"
        }
    }
}

class ActionLogEvent: LogEvent {
    var typeId: String?
    var source: String?
    var actionId: String?
    var data: [String: Any]?
    override func convertToPost() -> Data? {

        let params = ["user_id": self.userId ?? "null",
                      "user_agent": self.userAgent ?? "null",
                      "machine_ip": self.machineIp ?? "null",
                      "machine_cookie": self.machineCookie ?? "null",
                      "page_key": self.pageKey ?? "null",
                      "url": self.url ?? "null",
                      "type_id": self.typeId ?? "null",
                      "source": self.source ?? "null",
                      "action_id": self.actionId ?? "null"]
                      //"data": self.data] //as [String : Any]

        print(">>>>>>>> event params: ")
        print(params)

        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return nil
        }
        return httpBody
    }

}

class ErrorLoginEvent: ActionLogEvent {
    init(login: String?) {
        super.init()
        self.url = "/roadblock"
        self.typeId = "credentials"
        self.source = "roadblock"
        self.actionId = "wrong_credentials"
        self.data = ["email": login ?? ""]
    }
}

class SuccessLoginEvent: ActionLogEvent {
    override init() {
        super.init()
        self.url = "/roadblock"
        self.typeId = "credentials"
        self.source = "roadblock"
        self.actionId = "success"
    }
}

class OpenMenuEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "click"
        self.source = "drawer_menu"
        self.actionId = "open"
    }
}

class LogoutMenuEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "click"
        self.source = "drawer_menu"
        self.actionId = "logout"
    }
}

class DirectMessageEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "direct_msg"
        self.source = "message"
        self.actionId = "sent"
    }
}

class GroupMessageEvent: ActionLogEvent {
    var mentions: [String]?
    init(data: [String]) {
        super.init()
        self.typeId = "group"
        self.source = "message"
        self.actionId = "sent"
        self.mentions = data
    }
    override func convertToPost() -> Data? {

        let params: [String: Any] = ["user_id": self.userId ?? "null",
                      "user_agent": self.userAgent ?? "null",
                      "machine_ip": self.machineIp ?? "null",
                      "machine_cookie": self.machineCookie ?? "null",
                      "page_key": self.pageKey ?? "null",
                      "url": self.url ?? "null",
                      "type_id": self.typeId ?? "null",
                      "source": self.source ?? "null",
                      "action_id": self.actionId ?? "null",
                      "data": self.mentions ?? [""]]

        print(">>>>>>>> event params: ")
        print(params)

        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return nil
        }
        return httpBody
    }

}

class OpenByURLEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "direct_msg"
        self.source = "notification"
        self.actionId = "sent"
    }
}
