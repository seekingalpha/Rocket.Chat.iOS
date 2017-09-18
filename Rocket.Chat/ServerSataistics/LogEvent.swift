//
//  EventDescription.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/4/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class LogEvent: NSObject {
    //-
    var pageKey: String?
    //-
    var machineIp: String?
    //-

    override init() {
        super.init()
        self.machineIp = IPaddress.getIPAddress()
        self.pageKey = RCPageKey.generateUniqueString()
    }
    var moneURL: String {
        return ""
    }
    func convertToPost() -> Data? {
        return nil
    }
}

class PageMoneEvent: LogEvent {
    var userId: String? {
        return AuthManager.currentUser()?.identifier ?? "null"
    }
    var userAgent: String?
    var machineCookie: String?

    var url: String?
    var urlParams: String? = ""
    var refferer: String? = ""
    var reffererKey: String? = ""

    override init() {
        super.init()
        self.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_    5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36"
        self.machineCookie = UUID().uuidString

    }
    override func convertToPost() -> Data? {
        let params = [self.userId ?? "",
                      self.userAgent ?? "",
                      self.machineIp ?? "",
                      self.machineCookie ?? "",
                      self.url ?? "",
                      self.pageKey ?? "",
                      "",
                      "",
                      ""]
//                      self.urlParams,
//                      self.refferer,
//                      self.reffererKey]
        let joindParams = params.joined(separator: ";;;")
        print(">>>>>>>> event params: ")
        print(params)

        //        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
        //            return nil
        //        }
        return joindParams.data(using: .utf8)
    }
    override var moneURL: String {
        return "https://staging.seekingalpha.com/mone"
    }
}

class ChatPageLogEvent: PageMoneEvent {
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

        let params = ["machine_ip": self.machineIp ?? "",
                      "page_key": self.pageKey ?? "",
                      "type_id": self.typeId ?? "",
                      "source": self.source ?? "",
                      "action_id": self.actionId ?? ""]
                      //"data": self.data] //as [String : Any]

        print(">>>>>>>> event params: ")
        print(params)

//        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
//            return nil
//        }

        guard let httpBody = try? self.encodeParameters(parameters: params) else {
            return nil
        }

        return httpBody
    }

    override var moneURL: String {
        return "https://staging.seekingalpha.com/mone_event"
    }

    func encodeParameters(parameters: [String : String]) -> Data? {
        let parameterArray = parameters.map { (key, value) -> String in
            return "\(key)=\(value)"//self.percentEscapeString(string: value)
        }

        var HTTPBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
        return HTTPBody
    }

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
        let params: [String : Any] = ["machine_ip": self.machineIp ?? "",
                      "page_key": self.pageKey ?? "",
                      "type_id": self.typeId ?? "",
                      "source": self.source ?? "",
                      "action_id": self.actionId ?? "",
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
