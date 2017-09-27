//
//  EventDescription.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/4/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

@objc class LogEvent: NSObject {
    //-
    var pageKey: String? = nil

    override init() {
        super.init()
    }
    var moneURL: String {
        return ""
    }
    func convertToPost(previousPageKey: String?) -> Data? {
        return nil
    }
    func onlyAlphanumeric(string: String, separator: String) -> String {
        let result = string.replacingOccurrences(of: "\\W+", with: separator, options: NSString.CompareOptions.regularExpression, range: nil).trimmingCharacters(in: NSCharacterSet.whitespaces)
        return result
    }
}

@objc class PageMoneEvent: LogEvent {
    var userId: String? {
        return AuthManager.currentUser()?.email()
    }
    var machineCookie: String?

    var url: String?
    var urlParams: String? = ""
    var refferer: String? = ""
    var reffererKey: String? = ""

    override init() {
        super.init()
        let uuid = UIDevice.current.identifierForVendor?.uuidString
        self.machineCookie = uuid?.replacingOccurrences(of: "-", with: "", options: .literal, range: nil)
        self.pageKey = RCPageKey.generateUniqueString()
    }
    override func convertToPost(previousPageKey: String?) -> Data? {
        let params = ["",
                      self.pageKey ?? "",
                      "",
                      "",
                      self.url ?? "",
                      "",
                      self.machineCookie ?? "",
                      "",
                      self.userId ?? "",
                      "",
                      "",
                      "",
                      "",
                      "",
                      "",
                      "",
                      "{}",
                      "{}",
                      "{}",
                      "{}",
                      "{}",
                      "{}",
                      "{}",
                      "{}"]
        let joindParams = params.joined(separator: ";;;")
        let finalString = "mone=2;;;" + joindParams
        return finalString.data(using: .utf8)
    }
    override var moneURL: String {
        return "https://staging.seekingalpha.com/mone"
    }
}

@objc class ChatPageLogEvent: PageMoneEvent {
    init (subscription: Subscription?) {
        super.init()
        guard let displayName = subscription?.displayName() else {
            return
        }
        if subscription?.type == .directMessage {
            self.url = "/chat/direct_msg/" + self.onlyAlphanumeric(string: displayName, separator: ".")
        } else if subscription?.type == .group {
            self.url = "/chat/group/" + self.onlyAlphanumeric(string: displayName, separator: "-")
        }
    }
}

@objc class ActionLogEvent: LogEvent {
    var typeId: String?
    var source: String?
    var actionId: String?
    var data: [String: Any]?

    override func convertToPost(previousPageKey: String?) -> Data? {
        let params:[String: Any] = [
                      "key": previousPageKey ?? "",
                      "type": self.typeId ?? "",
                      "source": self.source ?? "",
                      "action": self.actionId ?? "",
                      "data": self.dataConverted(convertable: nil) ?? "{}",
                      "version": "2"]

        guard let httpBody = try? self.encodeParameters(parameters: params) else {
            return nil
        }

        return httpBody
    }

    override var moneURL: String {
        return "https://staging.seekingalpha.com/mone_event"
    }

    func convertParamsToString(parameters: [String : Any]) -> String {
        let parameterArray = parameters.map { (key, value) -> String in
            return "\(key)=\(value)"
        }
        return parameterArray.joined(separator: "&")
    }
    func encodeParameters(parameters: [String : Any]) -> Data? {
        let HTTPBody = self.convertParamsToString(parameters: parameters).data(using: String.Encoding.utf8)
        return HTTPBody
    }
    func dataConverted(convertable: [String:Any]?) -> String? {
        guard var convertable:[String: Any] = convertable else {
            return nil
        }
        do {
            if let theJSONData = try? JSONSerialization.data(
                withJSONObject: convertable,
                options: []) {
                let theJSONText = String(data: theJSONData,
                                         encoding: .utf8)
                return theJSONText
            }
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }

}

@objc class ErrorLoginEvent: ActionLogEvent {
    var login: String?
    init(login: String?) {
        super.init()
        self.typeId = "credentials"
        self.source = "roadblock"
        self.actionId = "wrong_credentials"
        self.login = login
    }
    override func dataConverted(convertable: [String:Any]?) -> String? {
        let convertable = ["email": login ?? ""]
        return super.dataConverted(convertable: convertable)
    }
}

@objc class SuccessLoginEvent: ActionLogEvent {
    var login: String?
    init(login: String?) {
        super.init()
        self.typeId = "credentials"
        self.source = "roadblock"
        self.actionId = "success"
        self.login = login
    }
    override func dataConverted(convertable: [String:Any]?) -> String? {
        let convertable = ["email": login ?? ""]
        return super.dataConverted(convertable: convertable)
    }
}

@objc class OpenMenuEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "click"
        self.source = "drawer_menu"
        self.actionId = "open"
    }
}

@objc class LogoutMenuEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "click"
        self.source = "drawer_menu"
        self.actionId = "logout"
    }
}

@objc class DirectMessageEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "direct_msg"
        self.source = "message"
        self.actionId = "sent"
    }
}

@objc class GroupMessageEvent: ActionLogEvent {
    var mentions: [String]?
    init(data: [String]) {
        super.init()
        self.typeId = "group"
        self.source = "message"
        self.actionId = "sent"
        self.mentions = data
    }

    override func dataConverted(convertable: [String:Any]?) -> String? {
        let convertable = ["mentions": self.mentions]
        return super.dataConverted(convertable: convertable)
    }

}

@objc class OpenByURLEvent: ActionLogEvent {
    override init() {
        super.init()
        self.typeId = "direct_msg"
        self.source = "notification"
        self.actionId = "sent"
    }
}
