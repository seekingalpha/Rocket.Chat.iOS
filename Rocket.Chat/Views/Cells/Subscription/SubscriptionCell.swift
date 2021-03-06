//
//  SubscriptionCell.swift
//  Rocket.Chat
//
//  Created by Rafael K. Streit on 8/4/16.
//  Copyright © 2016 Rocket.Chat. All rights reserved.
//

import UIKit

final class SubscriptionCell: UITableViewCell {

    static let identifier = "CellSubscription"
    static let directMessageIdentifier = "DirectMessage"

    internal let labelSelectedTextColor = UIColor(rgb: 0xFFFFFF, alphaVal: 1)
    internal let labelReadTextColor = UIColor(rgb: 0xFFFFFFF, alphaVal: 1)
    internal let labelUnreadTextColor = UIColor(rgb: 0xFFFFFF, alphaVal: 1)

    internal let defaultBackgroundColor = UIColor.clear
    internal let selectedBackgroundColor = UIColor(rgb: 0x555555, alphaVal: 1)//0.18)
    internal let highlightedBackgroundColor = UIColor(rgb: 0x555555, alphaVal: 1)// 0.27)

    var subscription: Subscription! {
        didSet {
            updateSubscriptionInformatin()
        }
    }

    var userName: String! {
        didSet {
            self.userAvatar.userName = userName
            self.userAvatar.layer.cornerRadius = self.userAvatar.frame.size.width / 2
            self.userAvatar.layer.masksToBounds = true
        }
    }

    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var userAvatar: AvatarView!
    @IBOutlet weak var counterConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelUnread: UILabel! {
        didSet {
            labelUnread.layer.cornerRadius = labelUnread.frame.size.height / 2 
            labelUnread.layer.masksToBounds = true
        }
    }
    func updateSubscriptionInformatin() {
        updateIconImage()

        let text = (subscription.roomDescription == "") ? subscription.name : subscription.roomDescription

        let titleFormatter = TitleFormatter()
        labelName.attributedText = titleFormatter.title(string: text)

        if subscription.unread > 0 || subscription.alert {
            labelName.textColor = labelUnreadTextColor
        } else {
            labelName.textColor = labelReadTextColor
        }

        labelUnread.alpha = subscription.unread > 0 ? 1 : 0
        let unread = "\(subscription.unread)"
        let size: CGSize = unread.size(attributes: [NSFontAttributeName: labelUnread.font])
        counterConstraint.constant = size.width + 10
        labelUnread.text = unread
    }

    func updateIconImage() {
        switch subscription.type {
        case .channel:
            // imageViewIcon.image = UIImage(named: "Hashtag")?.imageWithTint(.RCInvisible())
            break
        case .directMessage:
            /*var color: UIColor = .RCInvisible()

            if let user = subscription.directMessageUser {
                color = { _ -> UIColor in
                    switch user.status {
                    case .online: return .RCOnline()
                    case .offline: return .RCInvisible()
                    case .away: return .RCAway()
                    case .busy: return .RCBusy()
                    }
                }()
            }*/

            // imageViewIcon.image = UIImage(named: "Mention")?.imageWithTint(color)
            break
        case .group:
            // imageViewIcon.image = UIImage(named: "Lock")?.imageWithTint(.RCInvisible())
            break
        }
    }

}

extension SubscriptionCell {

    override func setSelected(_ selected: Bool, animated: Bool) {
        let transition = {
            switch selected {
            case true:
                self.backgroundColor = self.selectedBackgroundColor
            case false:
                self.backgroundColor = self.defaultBackgroundColor
            }
        }
        if animated {
            UIView.animate(withDuration: 0.18, animations: transition)
        } else {
            transition()
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let transition = {
            switch highlighted {
            case true:
                self.backgroundColor = self.highlightedBackgroundColor
            case false:
                self.backgroundColor = self.defaultBackgroundColor
            }
        }
        if animated {
            UIView.animate(withDuration: 0.18, animations: transition)
        } else {
            transition()
        }
    }
}
