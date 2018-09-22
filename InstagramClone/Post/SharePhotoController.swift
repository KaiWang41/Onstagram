//
//  SharePhotoController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/27/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class SharePhotoController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    var selectedImage: UIImage? {
        didSet {
            imageView.image = selectedImage
        }
    }
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .red
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let textView: PlaceholderTextView = {
        let tv = PlaceholderTextView()
        tv.placeholderLabel.text = "Add a caption..."
        tv.placeholderLabel.font = UIFont.systemFont(ofSize: 14)
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.autocorrectionType = .no
        return tv
    }()
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        layoutViews()
        
        // Location services.

            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.location = manager.location
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("location failure: ", error)
    }
    
    private func layoutViews() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        view.addSubview(containerView)
        containerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 100)
        
        containerView.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, width: 84)
        
        containerView.addSubview(textView)
        textView.anchor(top: containerView.topAnchor, left: imageView.rightAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingLeft: 4)
    }
    
    @objc private func handleShare() {
        guard let postImage = selectedImage else { return }
        guard let caption = textView.text else { return }
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        textView.isUserInteractionEnabled = false
        
        
        
        // Location
        var latitude = 90.0
        var longitude = 0.0
        if let location = location {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
        }
        
        var place = ""
        func createPost() {
            Database.database().createPost(withImage: postImage, caption: caption, latitude: latitude, longitude: longitude, location: place) { (err) in
                if err != nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.textView.isUserInteractionEnabled = true
                    return
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        if let location = location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                
                if error == nil {
                    
                    let placemark = placemarks?[0]
                    if let tf = placemark?.thoroughfare {
                        place.append(tf)
                    }
                    if let city = placemark?.subLocality {
                        if place != "" { place.append(", ")}
                        place.append(city)
                    }
                    if let state = placemark?.administrativeArea {
                        if place != "" { place.append(", ")}
                        place.append(state)
                    }
                    if let country = placemark?.country {
                        if place != "" { place.append(", ")}
                        place.append(country)
                    }
                    
                    createPost()
                }
            }
        } else {
            createPost()
        }
        
        
    }
    
    
}





