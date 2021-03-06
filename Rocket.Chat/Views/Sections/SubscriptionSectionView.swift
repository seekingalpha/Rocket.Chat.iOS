//
//  SubscriptionSectionView.swift
//  Rocket.Chat
//
//  Created by Rafael K. Streit on 29/10/16.
//  Copyright © 2016 Rocket.Chat. All rights reserved.
//

import UIKit

final class SubscriptionSectionView: UIView {

    fileprivate let defaultIconWidthConstraint = CGFloat(18)
    fileprivate let defaultTitleLeftConstraint = CGFloat(8)

    @IBOutlet fileprivate weak var icon: UIImageView!
    @IBOutlet fileprivate weak var iconWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var labelTitle: UILabel!
    @IBOutlet fileprivate weak var labelTitleLeftSpacingConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var subView: UIView!

    func setIconName(_ iconName: String?) {
        if let iconName = iconName {
            icon.image = UIImage(named: iconName)?.imageWithTint(UIColor(rgb: 0x9AB1BF, alphaVal: 1))
            iconWidthConstraint.constant = defaultIconWidthConstraint
            labelTitleLeftSpacingConstraint.constant = defaultTitleLeftConstraint
        } else {
            icon.image = nil
            iconWidthConstraint.constant = 0
            labelTitleLeftSpacingConstraint.constant = 0
        }
    }

    func setTitle(_ title: String?) {
        labelTitle.text = title?.uppercased()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.subView.backgroundColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        self.labelTitle.textColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
    }
}
