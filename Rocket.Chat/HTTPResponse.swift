//
//  HTTPResponse.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 8/23/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

public struct HTTPResponse {
    var isError = false
    var response:[String: Any]?
}
