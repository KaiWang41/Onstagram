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
    
    private let filterChoice : UIButton = {
        let ub = UIButton()
        ub.setTitle("Filter", for: .normal)
        ub.titleLabel?.font = UIFont(name:"Times New Roman", size: 20)
        ub.setTitleColor(.black, for: .normal)
        ub.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        return ub
    }()
    
    private let editChoice : UIButton = {
        let ub = UIButton()
        ub.setTitle("Edit", for: .normal)
        ub.titleLabel?.font = UIFont(name:"Times New Roman", size: 20)
        ub.setTitleColor(.black, for: .normal)
        ub.frame = CGRect(x: 0, y: 0, width: 0.5 * UIScreen.main.bounds.width, height: 0.2 * UIScreen.main.bounds.height)
        
        return ub
    }()
    
    
    
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
        
        brightnessSlider.tag = 0
        contrastSlider.tag = 1
        let contrastValue = Int(contrastSlider.value / 200) * 1000
        contrastValueLabel.text = ("\(contrastValue)")
        let brightnessValue = Int(brightnessSlider.value / 200) * 1000
        brightnessValueLabel.text = ("\(brightnessValue)")
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
            let displayinPercentage: Int = Int((sender.value/200) * 10000)
            brightnessValueLabel.text = ("\(displayinPercentage)")
            let beginImage = CIImage(image: imageToFilter.image!)
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(beginImage, forKey: kCIInputImageKey)
            filter!.setValue(sender.value, forKey: kCIInputBrightnessKey)
            let filteredImage = filter?.outputImage
            imageToFilter.image = UIImage(cgImage: ciContext.createCGImage(filteredImage!, from: (filteredImage?.extent)!)!)
        }else if sender.tag == 1{
            let displayinPercentage: Int = Int((sender.value/200) * 10000)
            contrastValueLabel.text = ("\(displayinPercentage)")
            let beginImage = CIImage(image: imageToFilter.image!)
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(beginImage, forKey: kCIInputImageKey)
            filter!.setValue(sender.value, forKey: kCIInputContrastKey)
            let filteredImage = filter?.outputImage
            imageToFilter.image = UIImage(cgImage: ciContext.createCGImage(filteredImage!, from: (filteredImage?.extent)!)!)
        }
    }
    
    @objc func filterButtonTapped(sender: UIButton) {
        let button = sender as UIButton
        
        imageToFilter.image = button.backgroundImage(for: UIControlState.normal)
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
        
        view.addSubview(filtersScrollView)
        filtersScrollView.anchor(top: imageToFilter.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 20, height:70 )
        
        
        view.addSubview(brightnessValueLabel)
        brightnessValueLabel.anchor(top: filtersScrollView.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingRight:20, height:20)
        
        view.addSubview(brightnessSlider)
        brightnessSlider.anchor(top: brightnessValueLabel.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingRight:20,height: 10)
        
        view.addSubview(contrastValueLabel)
        contrastValueLabel.anchor(top: brightnessSlider.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingRight:20,height:20)
        
        view.addSubview(contrastSlider)
        contrastSlider.anchor(top: contrastValueLabel.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingRight:20,height:10)
        
    }
    
    @objc private func handleNext() {
        guard let editedImage = imageToFilter.image else { return }
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let sharePhotoController = SharePhotoController()
        sharePhotoController.selectedImage = editedImage
        navigationController?.pushViewController(sharePhotoController, animated: true)
    }

}
