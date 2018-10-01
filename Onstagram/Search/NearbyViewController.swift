//
//  NearbyViewController.swift
//  Onstagram
//

import UIKit
import CoreLocation
import Firebase

class NearbyViewController: UICollectionViewController, CLLocationManagerDelegate {

    private var users = [User]()
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    private func dismissDueToLocation() {
        Helper.presentError(sender: self, message: "You have denied permission of use of your current location.")
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Location
        if CLLocationManager.authorizationStatus() == .denied {
            self.dismissDueToLocation()
        } else {
            if !CLLocationManager.locationServicesEnabled() {
                locationManager.requestWhenInUseAuthorization()
            }
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            } else {
                self.dismissDueToLocation()
            }
        }
        
        navigationItem.title = "People Nearby"
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(UserSearchCell.self, forCellWithReuseIdentifier: UserSearchCell.cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        refreshControl.beginRefreshing()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: ", error.localizedDescription)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.location = manager.location!
        Database.database().updateLocation(forUID: Auth.auth().currentUser!.uid, latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        manager.stopUpdatingLocation()
        
        fetchNearbyUsers()
    }
    
    private func fetchNearbyUsers() {
        
        Database.database().fetchNearbyUsers(forUID: Auth.auth().currentUser!.uid, latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude) { (users) in
            
            self.users = users
            
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        
        Database.database().removeLocation(forUID: Auth.auth().currentUser!.uid)
    }
    
    
    @objc private func handleRefresh() {
        collectionView?.refreshControl?.beginRefreshing()
        fetchNearbyUsers()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

            let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            userProfileController.user = users[indexPath.item]
            navigationController?.pushViewController(userProfileController, animated: true)
       
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserSearchCell.cellId, for: indexPath) as! UserSearchCell
            cell.user = users[indexPath.item]
            return cell
        
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout

extension NearbyViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
}
