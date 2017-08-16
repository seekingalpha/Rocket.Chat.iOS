//
//  ChatTitleView.swift
//  Rocket.Chat
//
//  Created by Rafael K. Streit on 10/10/16.
//  Copyright © 2016 Rocket.Chat. All rights reserved.
//

import UIKit

final class ChatTitleView: UIView {

    @IBOutlet weak var labelTitle: UILabel! {
        didSet {
            labelTitle.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }

    @IBOutlet weak var imageArrowDown: UIImageView! {
        didSet {
            imageArrowDown.image = imageArrowDown.image?.imageWithTint(.RCGray())
        }
    }

    var subscription: Subscription! {
        didSet {
            let text = (subscription.roomDescription == "") ? subscription.name : subscription.roomDescription
            let titleFormatter = TitleFormatter()
            labelTitle.attributedText = titleFormatter.navigationTitle(string: text, color: UIColor.white)
            switch subscription.type {
            case .channel:
                break
            case .directMessage:
                var color = UIColor.RCGray()

                if let user = subscription.directMessageUser {
                    color = { _ -> UIColor in
                        switch user.status {
                        case .online: return .RCOnline()
                        case .offline: return .RCGray()
                        case .away: return .RCAway()
                        case .busy: return .RCBusy()
                        }
                    }()
                }

                break
            case .group:
                break
            }
        }
    }

}
