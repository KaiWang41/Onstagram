//
//  UserSearchController.swift
//  Onstagram
//
//  See LICENSE file for license information.
//

import UIKit
import Firebase

class UserSearchController: UICollectionViewController {
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Enter username"
        sb.autocorrectionType = .no
        sb.autocapitalizationType = .none
        sb.barTintColor = .gray
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        return sb
    }()
    
    private var users = [User]()
    private var filteredUsers = [User]()
    
    // Suggest users
    private var suggestedUsers = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = searchBar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(UserSearchCell.self, forCellWithReuseIdentifier: UserSearchCell.cellId)
        // Nearby
        collectionView?.register(ButtonCell.self, forCellWithReuseIdentifier: ButtonCell.cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        searchBar.delegate = self
        
        // All users -> users
        fetchAllUsers()
        
        // Suggested users -> suggestedUsers
        fetchSuggestedUsers()
    }
    
    // User cells and button cell
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    
    // Suggest user algorithm
    private func fetchSuggestedUsers() {
        collectionView?.refreshControl?.beginRefreshing()
        
        let uid = Auth.auth().currentUser!.uid
        
        // 1. Followers
        Database.database().fetchFollowers(forUID: uid, completion: { (followers) in
            
            self.suggestedUsers.append(contentsOf: followers)
            
            // 2. Following same user
            Database.database().fetchUsersFollowingSameUser(forUID: uid, completion: { (users) in
                
                self.suggestedUsers.append(contentsOf: users)
                
                // 3. Liked same post
                Database.database().fetchUsersLikingSamePost(forUID: uid, completion: { (users) in
                    
                    self.suggestedUsers.append(contentsOf: users)
                    
                    // Remove from suggestiong users already following
                    Database.database().fetchFollowings(forUID: uid, completion: { (followings) in
                        
                        var filteredSuggestedUsers = [User]()
                        for suggestedUser in self.suggestedUsers {
                            if !followings.contains(suggestedUser) {
                                filteredSuggestedUsers.append(suggestedUser)
                            }
                        }
                        self.suggestedUsers = filteredSuggestedUsers
                        
                        // Show in collection view
                        self.filteredUsers = self.suggestedUsers
                        self.searchBar.text = ""
                        self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                    })
                })
            })
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
    }
    
    private func fetchAllUsers() {
        
        Database.database().fetchAllUsers(includeCurrentUser: false, completion: { (users) in
            self.users = users
        }) { (_) in
            ()
        }
    }
    
    @objc private func handleRefresh() {
        fetchSuggestedUsers()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        
        // Nearby
        if indexPath.section == 0 {
            let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            userProfileController.user = filteredUsers[indexPath.item]
            navigationController?.pushViewController(userProfileController, animated: true)
        } else {
           
//           let nearbyViewController = NearbyViewController()
//            navigationController?.pushViewController(nearbyViewController, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (section == 0) ? filteredUsers.count : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Nearby
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserSearchCell.cellId, for: indexPath) as! UserSearchCell
            cell.user = filteredUsers[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ButtonCell.cellId, for: indexPath) as! ButtonCell
            return cell
        }
        
    }
    
    // Nearby
    @objc func toNearby() {
        let vc = NearbyViewController(collectionViewLayout: UICollectionViewFlowLayout())
        navigationController?.pushViewController(vc, animated: true)
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension UserSearchController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
}

//MARK: - UISearchBarDelegate

extension UserSearchController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredUsers = []
        } else {
            filteredUsers = users.filter { (user) -> Bool in
                return user.username.lowercased().contains(searchText.lowercased())
            }
        }
        self.collectionView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
