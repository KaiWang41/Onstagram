//
//  User.swift
//  Onstagram
//
//  See LICENSE file for license information.
//

import Foundation

struct User: Equatable {
    
    let uid: String
    let username: String
    let profileImageUrl: String?
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? nil
    }
}
