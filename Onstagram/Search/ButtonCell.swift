//
//  ButtonCell.swift
//  Onstagram
//

import UIKit

class ButtonCell: UICollectionViewCell {
    
    private let button: UIButton = {
        let b = UIButton()
        b.backgroundColor = UIColor.lightGray
        b.setTitle("Search for People Nearby", for: .normal)
        b.addTarget(self, action: #selector(UserSearchController.toNearby), for: .touchUpInside)
        return b
    }()
    
    static var cellId = "buttonCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(button)
        button.anchor(left: leftAnchor, right: rightAnchor,  paddingLeft: 60, paddingRight: 60, height: 40)
        button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        button.layer.cornerRadius = 5
    }
}
