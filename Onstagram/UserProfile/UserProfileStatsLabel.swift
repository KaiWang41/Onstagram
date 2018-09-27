//
//  UserProfileStatsLabel.swift
//  Onstagram
//
//  Copyright © 2018 Group59. All rights reserved.
//

import UIKit

class UserProfileStatsLabel: UILabel {
    
    private var value: Int = 0
    private var title: String = ""
    
    init(value: Int, title: String) {
        super.init(frame: .zero)
        self.value = value
        self.title = title
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        numberOfLines = 0
        textAlignment = .center
        setAttributedText()
    }
    
    func setValue(_ value: Int) {
        self.value = value
        setAttributedText()
    }
    
    private func setAttributedText() {
        let attributedText = NSMutableAttributedString(string: "\(value)\n", attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)])
    attributedText.append(NSAttributedString(string: title, attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
        self.attributedText = attributedText
    }
}
