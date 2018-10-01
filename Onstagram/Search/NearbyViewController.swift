//
//  NearbyViewController.swift
//  Onstagram
//
//  Created by wky on 1/10/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
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

        fetchNearbyUsers()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: ", error.localizedDescription)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.location = manager.location!
        Database.database().updateLocation
        manager.stopUpdatingLocation()
    }
    
    private func fetchNearbyUsers() {
        collectionView?.refreshControl?.beginRefreshing()
        
        Database.database().fetchNearbyUsers()
        
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
    }
    
    
    @objc private func handleRefresh() {
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
