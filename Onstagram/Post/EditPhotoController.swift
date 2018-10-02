//
//  EditPhotoController.swift
//  Onstagram
//

import UIKit

class EditPhotoController: UIViewController {

    let ciContext = CIContext(options: nil)
    
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
    
    let contrastSlider = UISlider()
    let brightnessSlider = UISlider()
    private let contrastValueLabel = UILabel()
    private let brightnessValueLabel = UILabel()
    
    
    override var prefersStatusBarHidden: Bool { return true }
    
    // Filter
    let filtersScrollView = UIScrollView()
    let imageToFilter = UIImageView()
    let imageToEdit = UIImageView()
    let containerView  = UIView()
    
    
    
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
        imageToFilter.image = imageView.image
        imageToEdit.image = imageToFilter.image
        
        brightnessSlider.tag = 0
        contrastSlider.tag = 1
        brightnessSlider.maximumValue = 5
        brightnessSlider.minimumValue = -5
        brightnessSlider.value = 0
        contrastSlider.maximumValue = 5
        contrastSlider.minimumValue = -5
        contrastSlider.value = 0
        let contrastValue = Int((contrastSlider.value))
        contrastValueLabel.text = ("Contrast: \(contrastValue)")
        let brightnessValue = Int(brightnessSlider.value )
        brightnessValueLabel.text = ("Brightness: \(brightnessValue)")
        brightnessSlider.isContinuous = true
        contrastSlider.isContinuous = true
        brightnessSlider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        contrastSlider.addTarget(self, action: #selector(sliderValueDidChange(_:)), for: .valueChanged)
        
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
    }
    
    @objc func sliderValueDidChange(_ sender:UISlider!){
        if sender.tag == 0{
            let displayinPercentage: Int = Int(sender.value * 20)
            brightnessValueLabel.text = ("Brightness: \(displayinPercentage)")
            var beginImage = CIImage()
            if contrastSlider.value != 0{
                beginImage = CIImage(image: imageToEdit.image!)!
            }else{
                beginImage = CIImage(image: imageToFilter.image!)!
            }
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(beginImage, forKey: kCIInputImageKey)
            filter!.setValue(sender.value/20, forKey: kCIInputBrightnessKey)
            let filteredImage = filter?.outputImage
            imageToEdit.image = UIImage(cgImage: ciContext.createCGImage(filteredImage!, from: (filteredImage?.extent)!)!)
            containerView.bringSubview(toFront: imageToEdit)
        }else if sender.tag == 1{
            let displayinPercentage: Int = Int(sender.value * 20)
            contrastValueLabel.text = ("Contrast: \(displayinPercentage)")
            var beginImage = CIImage()
            if brightnessSlider.value != 0{
                beginImage = CIImage(image: imageToEdit.image!)!
            }else{
                beginImage = CIImage(image: imageToFilter.image!)!
            }
            let filter = CIFilter(name: "CIColorControls")
            print (beginImage)
            filter?.setValue(beginImage, forKey: kCIInputImageKey)
            filter!.setValue((sender.value), forKey: kCIInputContrastKey)
            let filteredImage = filter?.outputImage
            imageToEdit.image = UIImage(cgImage: ciContext.createCGImage(filteredImage!, from: (filteredImage?.extent)!)!)
            containerView.bringSubview(toFront: imageToEdit)
        }
    }
    
    @objc func filterButtonTapped(sender: UIButton) {
        let button = sender as UIButton
        
        imageToFilter.image = button.backgroundImage(for: UIControlState.normal)
        brightnessSlider.value = 0
        contrastSlider.value = 0
        let contrastValue = Int((contrastSlider.value))
        contrastValueLabel.text = ("Contrast: \(contrastValue)")
        let brightnessValue = Int(brightnessSlider.value )
        brightnessValueLabel.text = ("Brightness: \(brightnessValue)")
        containerView.bringSubview(toFront: imageToFilter)
    }
    
    // Filter
    private func layoutViews() {
        view.addSubview(containerView)
        containerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: UIScreen.main.bounds.width )
        
        containerView.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, height:UIScreen.main.bounds.width )
        
        containerView.addSubview(imageToFilter)
        imageToFilter.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, height:UIScreen.main.bounds.width )
        
        containerView.addSubview(imageToEdit)
        imageToEdit.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, height:UIScreen.main.bounds.width )
        
        
        let remainingHeight =  UIScreen.main.bounds.height - UIScreen.main.bounds.width
        view.addSubview(filtersScrollView)
        filtersScrollView.anchor(top: imageToEdit.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 20, height: 70 )
        
        
        view.addSubview(brightnessValueLabel)
        brightnessValueLabel.anchor(top: filtersScrollView.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 20, paddingLeft: 30, paddingRight:30, height: 0.05 * remainingHeight)
        
        view.addSubview(brightnessSlider)
        brightnessSlider.anchor(top: brightnessValueLabel.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 30, paddingRight:30,height: 0.02 * remainingHeight)
        
        view.addSubview(contrastValueLabel)
        contrastValueLabel.anchor(top: brightnessSlider.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 30, paddingRight:30, height: 0.05 * remainingHeight)
        
        view.addSubview(contrastSlider)
        contrastSlider.anchor(top: contrastValueLabel.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 30, paddingRight:30,height:0.02 * remainingHeight)
        
    }
    
    @objc private func handleNext() {
        guard let editedImage = imageToEdit.image else { return }
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let sharePhotoController = SharePhotoController()
        sharePhotoController.selectedImage = editedImage
        navigationController?.pushViewController(sharePhotoController, animated: true)
    }

}
