//
//  FirebaseUtilities.swift
//  Onstagram
//
//  See LICENSE file for license information.
//

import Foundation
import Firebase
import CoreLocation

extension Auth {
    func createUser(withEmail email: String, username: String, password: String, image: UIImage?, completion: @escaping (Error?) -> ()) {
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, err) in
            if let err = err {
                print("Failed to create user:", err)
                completion(err)
                return
            }
            guard let uid = user?.user.uid else { return }
            if let image = image {
                Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
                    Database.database().uploadUser(withUID: uid, username: username, profileImageUrl: profileImageUrl) {
                        completion(nil)
                    }
                })
            } else {
                Database.database().uploadUser(withUID: uid, username: username) {
                    completion(nil)
                }
            }
        })
    }
}

extension Storage {
    
    func uploadUserProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
        guard let uploadData = UIImageJPEGRepresentation(image, 1) else { return } //changed from 0.3
        
        let storageRef = Storage.storage().reference().child("profile_images").child(NSUUID().uuidString)
        
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload profile image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for profile image:", err)
                    return
                }
                guard let profileImageUrl = downloadURL?.absoluteString else { return }
                completion(profileImageUrl)
            })
        })
    }
    
    fileprivate func uploadPostImage(image: UIImage, filename: String, completion: @escaping (String) -> ()) {
        guard let uploadData = UIImageJPEGRepresentation(image, 1) else { return } //changed from 0.5
        
        let storageRef = Storage.storage().reference().child("post_images").child(filename)
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for post image:", err)
                    return
                }
                guard let postImageUrl = downloadURL?.absoluteString else { return }
                completion(postImageUrl)
            })
        })
    }
}

extension Database {

    //MARK: Users
    
    // Fetch all followers for user
    func fetchFollowers(forUID uid: String, completion: @escaping ([User]) -> ()) {
        Database.database().reference().child("followers").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var followers = [User]()
            if dictionary.count == 0 {
                completion(followers)
            } else {
                
                dictionary.forEach({ (key, _) in
                    
                    Database.database().fetchUser(withUID: key, completion: { (user) in
                        
                        followers.append(user)
                        if followers.count == dictionary.count {
                            completion(followers)
                        }
                    })
                })
            }
            
        })
    }
    
    // Fetch users that current user is following
    func fetchFollowings(forUID uid: String, completion: @escaping ([User]) -> ()) {
        Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var followings = [User]()
            if dictionary.count == 0 {
                completion([])
            } else {
                
                dictionary.forEach({ (key, _) in
                    
                    Database.database().fetchUser(withUID: key, completion: { (user) in
                        
                        followings.append(user)
                        if followings.count == dictionary.count {
                            completion(followings)
                        }
                    })
                })
            }
            
        })
    }
    
    // Fetch users liking same post as current user
    func fetchUsersLikingSamePost(forUID uid: String, completion: @escaping ([User]) -> ()) {
        completion([])
    }
    
    // Fetch users following the same user
    func fetchUsersFollowingSameUser(forUID uid: String, completion: @escaping ([User]) -> ()) {
        Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var users = [User]()
            if dictionary.count == 0 {
                completion([])
            } else {
                
                var n = 0
                dictionary.forEach({ (key, _) in
                    
                    Database.database().fetchFollowers(forUID: key
                        , completion: { (followers) in
                            
                            n += 1
                            for follower in followers {
                                if follower.uid != uid {
                                    if !users.contains(follower) {
                                        users.append(follower)
                                    }
                                }
                            }
                            
                            if n == dictionary.count {
                                completion(users)
                            }
                    })
                })
            }
            
        })
    }
    
    func fetchUser(withUID uid: String, completion: @escaping (User) -> ()) {
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userDictionary = snapshot.value as? [String: Any] else { return }
            let user = User(uid: uid, dictionary: userDictionary)
            completion(user)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func fetchAllUsers(includeCurrentUser: Bool = true, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var users = [User]()
            
            dictionaries.forEach({ (key, value) in
                if !includeCurrentUser, key == Auth.auth().currentUser?.uid {
                    completion([])
                    return
                }
                guard let userDictionary = value as? [String: Any] else { return }
                let user = User(uid: key, dictionary: userDictionary)
                users.append(user)
            })
            
            users.sort(by: { (user1, user2) -> Bool in
                return user1.username.compare(user2.username) == .orderedAscending
            })
            completion(users)
            
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func isFollowingUser(withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("following").child(currentLoggedInUserId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let isFollowing = snapshot.value as? Int, isFollowing == 1 {
                completion(true)
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func followUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let values = [uid: 1]
        Database.database().reference().child("following").child(currentLoggedInUserId).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            
            let values = [currentLoggedInUserId: 1]
            Database.database().reference().child("followers").child(uid).updateChildValues(values) { (err, ref) in
                if let err = err {
                    completion(err)
                    return
                }
                completion(nil)
            }
        }
    }
    
    func unfollowUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("following").child(currentLoggedInUserId).child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            
            Database.database().reference().child("followers").child(uid).child(currentLoggedInUserId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to remove user from followers:", err)
                    completion(err)
                    return
                }
                completion(nil)
            })
        }
    }
    
    fileprivate func uploadUser(withUID uid: String, username: String, profileImageUrl: String? = nil, completion: @escaping (() -> ())) {
        var dictionaryValues = ["username": username]
        if profileImageUrl != nil {
            dictionaryValues["profileImageUrl"] = profileImageUrl
        }
        
        let values = [uid: dictionaryValues]
        Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to upload user to database:", err)
                return
            }
            completion()
        })
    }
    
    //MARK: Posts
    
    func createPost(withImage image: UIImage, caption: String, latitude: Double, longitude: Double, location: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userPostRef = Database.database().reference().child("posts").child(uid).childByAutoId()
        
        let postId = userPostRef.key
        
        Storage.storage().uploadPostImage(image: image, filename: postId!) { (postImageUrl) in
            let values = ["imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "creationDate": Date().timeIntervalSince1970, "id": postId, "latitude": latitude, "longitude": longitude, "location": location] as [String : Any]
            
            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to database", err)
                    completion(err)
                    return
                }
                completion(nil)
            }
        }
    }
    
    func fetchPostsForUser(withUID uid: String, completion: @escaping ([Post]) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("posts").child(uid)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }

            var posts = [Post]()

            dictionaries.forEach({ (postId, value) in
                guard let postDictionary = value as? [String: Any] else { return }
                
                Database.database().fetchUser(withUID: uid, completion: { (user) in
                    var post = Post(user: user, dictionary: postDictionary)
                    post.id = postId

                    //check likes
                    Database.database().reference().child("likes").child(postId).child(currentLoggedInUser).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? Int, value == 1 {
                            post.likedByCurrentUser = true
                        } else {
                            post.likedByCurrentUser = false
                        }
                   
                    Database.database().numberOfLikesForPost(withPostId: postId, completion: { (count) in
                            post.likes = count
                        
                        // Liked users.
                        Database.database().fetchLikedUsersForPost(withId: postId, completion: { (users) in
                            
                            for user in users {
                                post.likedUsers.append(user.username)
                            }
                            
                            posts.append(post)
                            
                            if posts.count == dictionaries.count {
                                completion(posts)
                            }
                        }, withCancel: { (error) in
                            print(error.localizedDescription)
                        })
                        })
                        
                        
                        
                        
                        
                    }, withCancel: { (err) in
                        print("Failed to fetch like info for post:", err)
                    })
                })
            })
        }) { (err) in
            print("Failed to fetch posts:", err)
        }
    }
    
    
    
    // Get all liked users for a post.
    
    func fetchLikedUsersForPost(withId id: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        
        let ref = Database.database().reference().child("likes").child(id)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var users = [User]()
            dictionaries.forEach({ (uid, _) in
                Database.database().fetchUser(withUID: uid, completion: { (user) in
                    users.append(user)
                    if users.count == dictionaries.count {
                        completion(users)
                    }
                })
            })
            
            
        }) { (err) in
            print("Failed to fetch post likers:", err)
        }
    }
    
    
    
    
    
    func deletePost(withUID uid: String, postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child("posts").child(uid).child(postId).removeValue { (err, _) in
            if let err = err {
                print("Failed to delete post:", err)
                completion?(err)
                return
            }
            
            Database.database().reference().child("comments").child(postId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to delete comments on post:", err)
                    completion?(err)
                    return
                }
                
                Database.database().reference().child("likes").child(postId).removeValue(completionBlock: { (err, _) in
                    if let err = err {
                        print("Failed to delete likes on post:", err)
                        completion?(err)
                        return
                    }
                    
                    Storage.storage().reference().child("post_images").child(postId).delete(completion: { (err) in
                        if let err = err {
                            print("Failed to delete post image from storage:", err)
                            completion?(err)
                            return
                        }
                    })
                    
                    completion?(nil)
                })
            })
        }
    }
    
    func addCommentToPost(withId postId: String, text: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["text": text, "creationDate": Date().timeIntervalSince1970, "uid": uid] as [String: Any]
        
        let commentsRef = Database.database().reference().child("comments").child(postId).childByAutoId()
        commentsRef.updateChildValues(values) { (err, _) in
            if let err = err {
                print("Failed to add comment:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func fetchCommentsForPost(withId postId: String, completion: @escaping ([Comment]) -> (), withCancel cancel: ((Error) -> ())?) {
        let commentsReference = Database.database().reference().child("comments").child(postId)
        
        commentsReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var comments = [Comment]()
            
            dictionaries.forEach({ (key, value) in
                guard let commentDictionary = value as? [String: Any] else { return }
                guard let uid = commentDictionary["uid"] as? String else { return }
                
                Database.database().fetchUser(withUID: uid) { (user) in
                    let comment = Comment(user: user, dictionary: commentDictionary)
                    comments.append(comment)
                    
                    if comments.count == dictionaries.count {
                        comments.sort(by: { (comment1, comment2) -> Bool in
                            return comment1.creationDate.compare(comment2.creationDate) == .orderedAscending
                        })
                        completion(comments)
                    }
                }
            })
            
        }) { (err) in
            print("Failed to fetch comments:", err)
            cancel?(err)
        }
    }
    
    // Nearby users
    func updateLocation(forUID uid: String, latitude: Double, longitude: Double) {
        
        let values = ["latitude": latitude, "longitude": longitude]
        Database.database().reference().child("locations").child(uid).updateChildValues(values)
    }
    
    func removeLocation(forUID uid: String) {
        Database.database().reference().child("locations").child(uid).removeValue()
    }
    
    // Fetch all users in the Nearby View within 1000m
    func fetchNearbyUsers(forUID uid: String, latitude: Double, longitude: Double, completion: @escaping ([User]) -> ()) {
        
        Database.database().reference().child("locations").observeSingleEvent(of: .value) { (snapshot) in
            
            var users = [User]()
            if let dictionary = snapshot.value as? [String: Any] {
                

                dictionary.forEach({ (key, values) in
            
                        if let values = values as? [String: Double] {
                            
                            let otherLatitude = values["latitude"]
                            let otherLongitude = values["longitude"]
                            let location = CLLocation(latitude: latitude, longitude: longitude)
                            if location.distance(from: CLLocation(latitude: otherLatitude!, longitude: otherLongitude!)) < 1000 {
                                
                                Database.database().fetchUser(withUID: key, completion: { (user) in
                                    
                                    if key != uid { users.append(user) }
                                    if users.count + 1 == dictionary.count {
                                        completion(users)
                                    }
                                })
                            }
                        }
                    
                })
            }
        }
    }
    
    //MARK: Utilities
    
    func numberOfPostsForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("posts").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfFollowersForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("followers").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfFollowingForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfLikesForPost(withPostId postId: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("likes").child(postId).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
}
