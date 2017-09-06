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
}

class PageLoadingLogEvent: LogEvent {
}

class ActionLogEvent: LogEvent {
    var typeId: String?
    var source: String?
    var actionId: String?
    var data: String?

}

class ShowLoginPageEvent: PageLoadingLogEvent {
}
