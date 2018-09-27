//
//  Post.swift
//  Onstagram
//
//  See LICENSE file for license information.
//

import Foundation

struct Post {
    
    var id: String
    
    let user: User
    let imageUrl: String
    let caption: String
    let creationDate: Date
    
    var likes: Int = 0
    var likedByCurrentUser = false
    
    // All liked users for the post.
    var likedUsers = [String]()
    
    // Location
    let latitude: Double
    let longitude: Double
    let location: String
    
    init(user: User, dictionary: [String: Any]) {
        self.user = user
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.caption = dictionary["caption"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        
        // Location
        self.latitude = dictionary["latitude"] as? Double ?? 90
        self.longitude = dictionary["longitude"] as? Double ?? 0
        self.location = dictionary["location"] as? String ?? ""
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
    }
}
