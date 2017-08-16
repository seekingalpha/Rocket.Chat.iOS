//
//  TitleFormatter.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 8/11/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class TitleFormatter {
    private func stringFromHtml(string: String?, color: UIColor = .black, size: NSInteger = 4) -> NSAttributedString? {
        do {
            guard let string = string else {
                return nil
            }
            let stringSize = String(size)
            let modString = "<font color=\"white\" face=\"Helvetica Neue\" size=\"" + stringSize + "\" >" + string + "</font>"

            let data = modString.data(using: String.Encoding.utf8, allowLossyConversion: true)
            if let d = data {
                let str = try NSAttributedString(data: d,
                                                 options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
                                                 documentAttributes: nil)
                return str
            }
        } catch {
        }
        return nil
    }

    func replaceDotWithSpace(string: String?) -> String? {
        guard let string = string else {
            return nil
        }
        return string.replacingOccurrences(of: ".", with: " ", options: .literal, range: nil)
    }

    func title(string: String?, color: UIColor = .black) -> NSAttributedString? {
        return self.stringFromHtml(string: self.replaceDotWithSpace(string: string), color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    }
    func navigationTitle(string: String?, color: UIColor = .black) -> NSAttributedString? {
        return self.stringFromHtml(string: self.replaceDotWithSpace(string: string), color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), size: 5)
    }
}
