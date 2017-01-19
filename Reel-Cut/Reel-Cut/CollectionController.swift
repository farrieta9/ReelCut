//
//  CollectionController.swift
//  Reel-Cut
//
//  Created by Francisco Arrieta on 10/24/16.
//  Copyright © 2016 lil9porkchop. All rights reserved.
//

import UIKit
import Photos

class CollectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    private let photoCellId = "photoCellId"
    var gallery = [UIImage]()
    var upperBound: Int = 50
    var lowerBound: Int = 50
    
    let indicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.clipsToBounds = true
        view.activityIndicatorViewStyle = .whiteLarge
        view.hidesWhenStopped = true
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        return view
    }()
    
    let permissionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Need access to photos to use app"
        label.textAlignment = .center
        label.isHidden = true
        label.textColor = UIColor(white: 0.1, alpha: 0.5)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .white
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: photoCellId)
        setupView()
        setUpIndicator()
        checkPhotoLibraryPermission()
    }
    
    private func setupView() {
        collectionView?.addSubview(permissionLabel)
        
        permissionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        permissionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        permissionLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        permissionLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    func setUpIndicator() {
        self.view.addSubview(indicator)
        
        // x, y, width, height
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 64).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
    }
    
    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            fetchPhotos(10)
            break
            
        case .denied, .restricted:
            print("denied or restricted. Ask user to give permission")
            permissionLabel.isHidden = false
            break
            
        case .notDetermined:
            askForPermissionToPhotoLibrary()
            break
        }
    }
    
    private func askForPermissionToPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization() { (status) -> Void in
            switch status {
                case .authorized:
                    self.fetchPhotos(10)
                    break
                
                case .denied, .restricted: break
                // as above
                case .notDetermined: break
                // won't happen but still
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory warning")
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gallery.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellId, for: indexPath) as! PhotoCell
        cell.imageView.image = gallery[indexPath.item]
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipeRight(_:)))
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipeRight(_:)))
        swipeRightGesture.direction = .right
        swipeLeftGesture.direction = .left
        cell.addGestureRecognizer(swipeRightGesture)
        cell.addGestureRecognizer(swipeLeftGesture)
        cell.collectionController = self
        
        return cell
    }
    
    func handleSwipeRight(_ sender: UISwipeGestureRecognizer) {
        guard let cell = sender.view as? PhotoCell else { return }
        
        if let indexPath = collectionView?.indexPath(for: cell) {
            
            let fetchOptions: PHFetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
            let assetToDelete: PHAsset = fetchResult[indexPath.item]
            let arrayToDelete = NSArray(object: assetToDelete)
            
            PHPhotoLibrary.shared().performChanges({ 
                PHAssetChangeRequest.deleteAssets(arrayToDelete)
            }, completionHandler: { (success, error) in
                if success {
                    // user clicked on Allow
                    DispatchQueue.main.async {
                        self.gallery.remove(at: indexPath.item)
                        self.collectionView?.deleteItems(at: [indexPath])
                    }
                }
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: (view.frame.height / 2) - 40)
    }
    
    func fetchPhotos(_ quantity: Int) {
        
        if upperBound < 0 {
            upperBound =  quantity
        }
        
        indicator.startAnimating()
        gallery.removeAll()
        let imageManager = PHImageManager()
        let requestOptions = PHImageRequestOptions()
        let fetchOptions = PHFetchOptions()
        
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        print(assets.count)
        print(min(assets.count, upperBound))
        
        upperBound = min(assets.count, upperBound)
        lowerBound = max(0, upperBound - 50)
        
        if lowerBound < 0 {
            lowerBound = 0
            upperBound = min(assets.count, upperBound)
        }
        
        if upperBound < 1 {
            upperBound = min(assets.count, upperBound + 50)
        }
        
        for index in lowerBound..<upperBound {
            imageManager.requestImage(for: assets[index], targetSize: self.view.frame.size, contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, _) in
                if let image = image {
                    self.gallery.append(image)
                }
            })
        }
        
        collectionView?.reloadData()
        indicator.stopAnimating()
    }
    
    
    var startingFrame: CGRect?
    var blackBackGroundView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomInForStartingImageView(startingImageView: UIImageView) {
        
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        let zoomingImageView = UIImageView(frame: startingFrame!)
        
        
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.contentMode = .scaleAspectFit
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackGroundView = UIView(frame: keyWindow.frame)
            blackBackGroundView?.backgroundColor = .black
            blackBackGroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackGroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.blackBackGroundView!.alpha = 1
                
                // Make the image fill up the screen
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: keyWindow.frame.height)
                zoomingImageView.center = keyWindow.center
                
            }, completion: nil)
        }
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            // need to animate back to controller
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackGroundView?.alpha = 0

            }, completion: { (completed: Bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            print("bottom")
            upperBound += 30
            fetchPhotos(10)
        }
        
        if (scrollView.contentOffset.y < 0){
            print("top")
            upperBound -= 30
            fetchPhotos(10)
        }
    }
}















