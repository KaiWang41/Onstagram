//
//  HomeController.swift
//  Onstagram
//
//  See LICENSE file for license information.
//

import UIKit
import Firebase
import CoreLocation

class HomeController: HomePostCellViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
    // Loation
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: HomePostCell.cellId)
        collectionView?.backgroundView = HomeEmptyStateView()
        collectionView?.backgroundView?.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateHomeFeed, object: nil)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        fetchAllPosts(sort: "time")
    }
    
    // Location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        location = manager.location
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("location error: ", error)
    }
    
    private func configureNavigationBar() {
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo").withRenderingMode(.alwaysOriginal))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "inbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleSort))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }
    
    private func fetchAllPosts(sort: String) {
        showEmptyStateViewIfNeeded()
        if sort == "location" {
            // Location
            if CLLocationManager.authorizationStatus() != .denied {
                if !CLLocationManager.locationServicesEnabled() {
                    locationManager.requestWhenInUseAuthorization()
                }
                if CLLocationManager.locationServicesEnabled() {
                    locationManager.delegate = self
                    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                    locationManager.startUpdatingLocation()
                } else {
                    Helper.presentError(sender: self, message: "You have denied permission of location services.")
                    return
                }
            } else {
                Helper.presentError(sender: self, message: "You have denied permission of location services.")
                return
            }
        }
        fetchPostsForCurrentUser(sort: sort)
        fetchFollowingUserPosts(sort: sort)
    }
    
    private func fetchPostsForCurrentUser(sort: String) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        
        Database.database().fetchPostsForUser(withUID: currentLoggedInUserId, completion: { (posts) in
            self.posts.append(contentsOf: posts)
            
            if sort == "time" {
                self.posts.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                })
            } else {
                self.posts.sort(by: { (p1, p2) -> Bool in
                    return self.getDistance(post: p1) <= self.getDistance(post: p2)
                })
            }
                
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    private func fetchFollowingUserPosts(sort: String) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        
        Database.database().reference().child("following").child(currentLoggedInUserId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userIdsDictionary = snapshot.value as? [String: Any] else { return }
            
            userIdsDictionary.forEach({ (uid, value) in
                
                Database.database().fetchPostsForUser(withUID: uid, completion: { (posts) in
                    
                    self.posts.append(contentsOf: posts)
                    
                    if sort == "time" {
                        self.posts.sort(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                    } else {
                        self.posts.sort(by: { (p1, p2) -> Bool in
                            return self.getDistance(post: p1) <= self.getDistance(post: p2)
                        })
                    }
                    
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                    
                }, withCancel: { (err) in
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    // Calculate post location distance to current location.
    func getDistance(post: Post) -> Double {
        if let location = location {
            return location.distance(from: CLLocation(latitude: post.latitude, longitude: post.longitude))
        } else {
            return Double.infinity
        }
    }
    
    override func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfFollowingForUser(withUID: currentLoggedInUserId) { (followingCount) in
            Database.database().numberOfPostsForUser(withUID: currentLoggedInUserId, completion: { (postCount) in
                
                if followingCount == 0 && postCount == 0 {
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                        self.collectionView?.backgroundView?.alpha = 1
                    }, completion: nil)
                    
                } else {
                    self.collectionView?.backgroundView?.alpha = 0
                }
            })
        }
    }
    
    @objc private func handleRefresh() {
        posts.removeAll()
        fetchAllPosts(sort: "time")
    }
    
    // Take photo
    @objc private func handleCamera() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        imagePickerController.showsCameraControls = true
        
        // Overlay grid
        let gridImageView = UIImageView(image: UIImage(named: "light_grid"))
        gridImageView.contentMode = .scaleToFill
        gridImageView.frame = imagePickerController.view!.frame
        imagePickerController.cameraOverlayView = gridImageView
        
        present(imagePickerController, animated: true)
    }
    
    // Image delegates
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let ac = UIAlertController(title: nil, message: "Save to library?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        ac.addAction(UIAlertAction(title: "Yes", style: .default, handler: { alert in
            
            picker.dismiss(animated: true, completion: nil)
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }))
        
        picker.present(ac, animated: true)
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo info: UnsafeRawPointer) {
        
        if let err = error {
            let message = err.localizedDescription
            Helper.presentError(sender: self, message: message)
        } else {
            let ac = UIAlertController(title: "Save Successful", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    
    // Sort by date time or location (nearest).
    @objc private func handleSort() {
        let ac = UIAlertController(title: nil, message: "Sort By", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Date / Time", style: .default, handler: { _ in
            
            self.handleRefresh()
        }))
        ac.addAction(UIAlertAction(title: "Location", style: .default, handler: { _ in
            
            self.posts.removeAll()
            self.fetchAllPosts(sort: "location")
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCell.cellId, for: indexPath) as! HomePostCell
        if indexPath.item < posts.count {
            cell.post = posts[indexPath.item]
        }
        cell.delegate = self
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension HomeController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dummyCell = HomePostCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1000))
        dummyCell.post = posts[indexPath.item]
        dummyCell.layoutIfNeeded()
        
        var height: CGFloat = dummyCell.header.bounds.height
        height += view.frame.width
        height += 24 + 2 * dummyCell.padding //bookmark button + padding
        height += dummyCell.captionLabel.intrinsicContentSize.height + 8
        return CGSize(width: view.frame.width, height: height)
    }
}
