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
    
    // Filter
    let filtersScrollView = UIScrollView()
    let imageToFilter = UIImageView()
    
    
    
    
    var CIFilterNames = [
        "CIPhotoEffectChrome",
        "CIPhotoEffectFade",
        "CIPhotoEffectInstant",
        "CIPhotoEffectNoir",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTonal",
        "CIPhotoEffectTransfer",
        "CISepiaTone"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        
        
        // Filter
        var xCoord: CGFloat = 5
        let yCoord: CGFloat = 5
        let buttonWidth:CGFloat = 70
        let buttonHeight: CGFloat = 70
        let gapBetweenButtons: CGFloat = 5
        
        
        var itemCount = 0
        
        for i in 0..<CIFilterNames.count {
            itemCount = i
            
            // Button properties
            let filterButton = UIButton(type: .custom)
            filterButton.frame = CGRect(origin: CGPoint(x:xCoord, y: yCoord), size: CGSize(width: buttonWidth, height: buttonHeight))
            filterButton.tag = itemCount
            filterButton.addTarget(self, action:#selector(filterButtonTapped), for: .touchUpInside)
            filterButton.layer.cornerRadius = 6
            filterButton.clipsToBounds = true
            let ciContext = CIContext(options: nil)
            let coreImage = CIImage(image: imageView.image!)
            let filter = CIFilter(name: "\(CIFilterNames[i])" )
            filter!.setDefaults()
            filter!.setValue(coreImage, forKey: kCIInputImageKey)
            let filteredImageData = filter!.value(forKey: kCIOutputImageKey) as! CIImage
            let filteredImageRef = ciContext.createCGImage(filteredImageData, from: filteredImageData.extent)
            let imageForButton = UIImage(cgImage: filteredImageRef!)
            filterButton.setBackgroundImage(imageForButton, for: .normal)
            xCoord +=  buttonWidth + gapBetweenButtons
            filtersScrollView.addSubview(filterButton)
        }
        
        
        filtersScrollView.contentSize = CGSize(width:buttonWidth * CGFloat(itemCount+2), height: yCoord)
        
        layoutViews()
        
        // Location services.

            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        
    }
    
    @objc func filterButtonTapped(sender: UIButton) {
        let button = sender as UIButton
        
        imageToFilter.image = button.backgroundImage(for: UIControlState.normal)
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.location = manager.location
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("location failure: ", error)
    }
    
    
    // Filter
    private func layoutViews() {
        let containerView  = UIView()
        view.addSubview(containerView)
        containerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: UIScreen.main.bounds.width )
        
        containerView.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, height:UIScreen.main.bounds.width )
        
        containerView.addSubview(imageToFilter)
        imageToFilter.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, height:UIScreen.main.bounds.width )
        
        view.addSubview(textView)
        textView.anchor(top: containerView.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 30, height:0.2 * UIScreen.main.bounds.width)
        view.addSubview(filtersScrollView)
        filtersScrollView.anchor(top: textView.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 50, height: 0.3 * UIScreen.main.bounds.width)
    }
    
    @objc private func handleShare() {
        guard let postImage = imageToFilter.image else { return }
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





