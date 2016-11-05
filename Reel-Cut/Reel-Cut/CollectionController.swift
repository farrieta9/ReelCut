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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .white
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: photoCellId)
        setUpIndicator()
        checkPhotoLibraryPermission()
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
        
        indicator.startAnimating()
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
        
        for index in 0..<upperBound {
            imageManager.requestImage(for: assets[index], targetSize: self.view.frame.size, contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, _) in
                if let image = image {
                    self.gallery.append(image)
                }
            })

        }
        
        collectionView?.reloadData()
        indicator.stopAnimating()
        
    }
}









