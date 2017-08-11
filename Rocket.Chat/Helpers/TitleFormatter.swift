//
//  TitleFormatter.swift
//  Rocket.Chat
//
//  Created by Alexander Bugara on 8/11/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import Foundation

class TitleFormatter {
    private func stringFromHtml(string: String?) -> NSAttributedString? {
        do {
            let data = string?.data(using: String.Encoding.utf8, allowLossyConversion: true)
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

    func title(string: String?) -> NSAttributedString? {
        return self.stringFromHtml(string: self.replaceDotWithSpace(string: string))
    }
}
