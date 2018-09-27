//
//  Comment.swift
//  Onstagram
//
//  Copyright © 2018 Group59. All rights reserved.
//

import Foundation

struct Comment {
    
    let user: User
    let text: String
    let creationDate: Date
    let uid: String
    
    init(user: User, dictionary: [String: Any]) {
        self.user = user
        self.text = dictionary["text"] as? String ?? ""
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        
        self.uid = dictionary["uid"] as? String ?? ""
    }
}
