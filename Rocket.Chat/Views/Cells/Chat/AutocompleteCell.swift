//
//  AutocompleteCell.swift
//  Rocket.Chat
//
//  Created by Rafael K. Streit on 04/11/16.
//  Copyright © 2016 Rocket.Chat. All rights reserved.
//

import UIKit

final class AutocompleteCell: UITableViewCell {

    static let minimumHeight = CGFloat(44)
    static let identifier = "AutocompleteCell"

    @IBOutlet weak var imageViewIcon: UIImageView!

    @IBOutlet weak var avatarViewContainer: AvatarView! {
        didSet {
            if let avatarView = AvatarView.instantiateFromNib() {
                avatarView.frame = avatarViewContainer.bounds
                avatarViewContainer.addSubview(avatarView)
                self.avatarView = avatarView
            }
        }
    }

    weak var avatarView: AvatarView! {
        didSet {
            avatarView.layer.cornerRadius = avatarView.frame.size.width / 2
            avatarView.layer.masksToBounds = true
            avatarView.labelInitialsFontSize = 15
        }
    }

    @IBOutlet weak var labelTitle: UILabel!

}
