//
//  Helper.swift
//  InstagramClone
//
//  Created by wky on 22/9/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

class Helper: NSObject {

    static func presentError(sender: UIViewController, message: String) {
        
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        sender.present(ac, animated: true)
    }
}