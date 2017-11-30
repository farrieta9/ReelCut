//
//  MainController.swift
//  ReelCut
//
//  Created by Francisco Arrieta on 6/5/17.
//  Copyright © 2017 Francisco Arrieta. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class RootController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var isLoadingPhotos: Bool = true
    private let swipeDirections: [UISwipeGestureRecognizerDirection] = [.right, .left]
    private let firstOpen = "firstOpen"
    var shouldScrollToItem: Bool = false
    var isViewingPhoto: Bool = false
    var timer: Timer? = nil
    var startingFrame: CGRect?
    var blackBackGroundView: UIView?
    var startingImageView: UIImageView?
    var startIndex: Int = 0
    var endIndex: Int = 30
    private let cellId = "cellId"
    var images = [UIImage]()
    var assets = [PHAsset]()
    
    let permissionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Need access to photos to use app"
        label.textAlignment = .center
        label.isHidden = true
        label.textColor = UIColor(white: 0.1, alpha: 0.5)
        return label
    }()

    let reelCutImageView: UIImageView = {
        let image = UIImage(named: "transparent-reelcut-1000x1000.png")
        let iv = UIImageView(image: image)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.backgroundColor = UIColor.init(r: 1.0, g: 0, b: 0, alpha: 0)
        return iv
    }()
    
    let livePhotoView: PHLivePhotoView = {
        let photoView = PHLivePhotoView()
        photoView.contentMode = .scaleAspectFit
        photoView.isUserInteractionEnabled = true
        return photoView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let collectionView = collectionView else { return }
        
        collectionView.backgroundColor = .white
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: cellId)
        
        view.addSubview(reelCutImageView)
        view.addSubview(permissionLabel)
        
        // x, y, width, height
        reelCutImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        reelCutImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        reelCutImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        reelCutImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        permissionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        permissionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        permissionLabel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        permissionLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let defaults = UserDefaults.standard
        
        if defaults.bool(forKey: firstOpen) {
            askForPermissionToPhotoLibrary()
        } else {
            let alert = UIAlertController(title: "Allow access to photos?", message: "", preferredStyle: .alert)
            
            let allowAction = UIAlertAction(title: "Allow", style: .default) { (action) in
                self.askForPermissionToPhotoLibrary()
            }
            
            let denyAction = UIAlertAction(title: "Deny", style: .default) { (action) in
                print("Not allowed")
                self.permissionLabel.isHidden = false
            }
            
            alert.addAction(denyAction)
            alert.addAction(allowAction)
            
            defaults.set(true, forKey: firstOpen)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func rotateViewIndefinitely(targetView: UIView, duration: Double = 1.0) {
        // Rotate <targetView> indefinitely
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            targetView.transform = targetView.transform.rotated(by: CGFloat.pi)
        }) { finished in
            
            if self.isLoadingPhotos {
                self.rotateViewIndefinitely(targetView: targetView, duration: duration)
            }
        }
    }
    
    private func startLoadingAnimation() {
        isLoadingPhotos = true
        reelCutImageView.isHidden = false
        rotateViewIndefinitely(targetView: reelCutImageView)
    }
    
    private func stopLoadingAnimation() {
        isLoadingPhotos = false
        reelCutImageView.isHidden = true
    }
    
    func performZoomInForStartingImageView(startingImageView: UIImageView, asset: PHAsset) {
        
        if isViewingPhoto { return }
        
        var isLivePhoto: Bool = false
        let targetSize = CGSize(width: 350, height: 350)
        
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .opportunistic
        
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (livePhoto, info) in
            if let livePhoto = livePhoto {
                self.livePhotoView.livePhoto = livePhoto
                self.livePhotoView.startPlayback(with: .full)
                isLivePhoto = true
            }
        })
        
        isViewingPhoto = true
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        
        
        if isLivePhoto {
            livePhotoView.frame = startingFrame!
//            livePhotoView.isUserInteractionEnabled = true
//            livePhotoView.contentMode = .scaleAspectFit
            livePhotoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
            
            if let keyWindow = UIApplication.shared.keyWindow {
                
                blackBackGroundView = UIView(frame: keyWindow.frame)
                blackBackGroundView?.backgroundColor = .black
                blackBackGroundView?.alpha = 0
                
                keyWindow.addSubview(blackBackGroundView!)
                keyWindow.addSubview(livePhotoView)
                
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                    self.blackBackGroundView!.alpha = 1
                    
                    // Make the image fill up the screen
                    self.livePhotoView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: keyWindow.frame.height)
                    self.livePhotoView.center = keyWindow.center
                    
                }, completion: nil)
            }
            
        } else {
            let zoomingImageView = UIImageView(frame: startingFrame!)
            zoomingImageView.image = startingImageView.image
            zoomingImageView.isUserInteractionEnabled = true
            zoomingImageView.contentMode = .scaleAspectFit
            zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
            if let keyWindow = UIApplication.shared.keyWindow {
                
                blackBackGroundView = UIView(frame: keyWindow.frame)
                blackBackGroundView?.backgroundColor = .black
                blackBackGroundView?.alpha = 0
                
                //            keyWindow.addSubview(livePhotoView)
                keyWindow.addSubview(blackBackGroundView!)
                keyWindow.addSubview(zoomingImageView)
                //            keyWindow.addSubview(livePhotoView)
                
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                    self.blackBackGroundView!.alpha = 1
                    
                    // Make the image fill up the screen
                    zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: keyWindow.frame.height)
                    zoomingImageView.center = keyWindow.center
                    
                }, completion: nil)
            }
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            // need to animate back to controller
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackGroundView?.alpha = 0
                
            }, completion: { (completed: Bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
                self.isViewingPhoto = false
            })
        }
    }
    
    private func assetsFetchOptions() -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        //        fetchOptions.fetchLimit = 15 // 50 is a good number of photos to display
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchOptions.sortDescriptors = [sortDescriptor]
        return fetchOptions
    }
    
    var reachedBottomOfPhotos: Bool = false
    
    
    private func fetchPhotos() {
        //        beginLoadingAnimation()
        //        loadingIndicator.startAnimating()
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: assetsFetchOptions())
        
        endIndex = min(endIndex, allPhotos.count)
        startIndex = max(0, endIndex - 30) // 30 is endIndex initial value
        
        print("Start index -> \(startIndex)")
        print("End index -> \(endIndex)")
        
        if endIndex >= allPhotos.count {
            reachedBottomOfPhotos = true
        } else {
            reachedBottomOfPhotos = false
        }
        
        DispatchQueue.global(qos: .background).async {
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 10, height: 10)
            let options = PHImageRequestOptions()
            options.isSynchronous = true

            for index in self.startIndex..<self.endIndex {
                imageManager.requestImage(for: allPhotos[index], targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image, info) in
                    if let image = image {
                        self.images.append(image)
                        self.assets.append(allPhotos[index])
                    }

                    if index == self.endIndex - 1 {
                        self.reloadCollectionView()
                    }
                })
            }
        }
    }
    
    func reloadCollectionView() {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
            self.endLoadingAnimation()
        }
    }
    
    func askForPermissionToPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .notDetermined, .denied, .restricted:
                print("need access to photos")
                self.permissionLabel.isHidden = false
                break
            case .authorized:
                self.fetchPhotos()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("running out of memory")
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PhotoCell
        
        for direction in swipeDirections {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            swipeGesture.direction = direction
            cell.addGestureRecognizer(swipeGesture)
        }
        
        cell.imageView.image = images[indexPath.item]
        cell.parentController = self
        cell.asset = assets[indexPath.item]
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? PhotoCell else { return }
        
        let selectedAsset = self.assets[indexPath.item]
        
        let imageManager = PHImageManager.default()
        let targetSize = PHImageManagerMaximumSize
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        imageManager.requestImage(for: selectedAsset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image, info) in
            cell.imageView.image = image
        })
    }
    
    func addPhotoToTopOfStack() {
        
        if startIndex <= 0 {
            startIndex = 0
            print("Already at the top... returning")
            return
        }
        
        startIndex -= 1
        
        print("Fetching a photo")
        print("startIndex = \(startIndex)")
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: assetsFetchOptions())
        
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 20, height: 20)
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        
        imageManager.requestImage(for: allPhotos[startIndex], targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image, info) in
            
            if let image = image {
                self.images.insert(image, at: 0)
                self.assets.insert(allPhotos[self.startIndex], at: 0)
                
                let indexPathOfTopCell = IndexPath(item: 0, section: 0)
                self.collectionView?.insertItems(at: [indexPathOfTopCell])
                
                self.images.removeLast()
                self.assets.removeLast()
                self.endIndex -= 1
                print("photo count \(self.images.count)")
                
                let indexOfBottomCell = IndexPath(item: self.images.count - 1, section: 0)
                self.collectionView?.deleteItems(at: [indexOfBottomCell])
            }
        })
    }
    
    func fetchMorePhotos() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer) in
            self.shouldScrollToItem = true
            
            self.beginLoadingPhotoAnimation()
        })
    }
    
    func beginLoadingPhotoAnimation() {
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackGroundView = UIView(frame: keyWindow.frame)
            blackBackGroundView?.backgroundColor = .black
            blackBackGroundView?.alpha = 0
            keyWindow.addSubview(blackBackGroundView!)
            self.startLoadingAnimation()

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackGroundView?.alpha = 0.25
                
            }, completion: { (completed: Bool) in
                
                self.images.removeAll()
                self.assets.removeAll()
                self.endIndex += 15
                self.startIndex += 15
                self.fetchPhotos()
            })
        }
    }
    
    func endLoadingAnimation() {
        
        if shouldScrollToItem {
            let previousCellIndexPath = IndexPath(item: 15 - 1, section: 0)
            self.collectionView?.scrollToItem(at: previousCellIndexPath, at: .bottom, animated: false)
        }
        self.stopLoadingAnimation()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.blackBackGroundView?.alpha = 0
        }) { (completed: Bool) in
            
        }
    }
    
    private func deletePhotoAt(indexPath: IndexPath){
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        let assetToDelete: PHAsset = fetchResult[startIndex + indexPath.item]
        let arrayToDelete = NSArray(object: assetToDelete)
        print("Attempting to delete photo at index: \(indexPath.row)")
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(arrayToDelete)
        }, completionHandler: { (success, error) in
            
            if success {
                self.removePhotoFromCacheAt(indexPath: indexPath)
            }
        })
    }
    
    private func removePhotoFromCacheAt(indexPath: IndexPath) {
        print("deleted photo successfully")
        DispatchQueue.main.async {
            self.images.remove(at: indexPath.item)
            self.assets.remove(at: indexPath.item)
            self.endIndex -= 1
            print("Photos left in display -> \(self.images.count)")
            self.collectionView?.deleteItems(at: [indexPath])
        }
    }
    
    @objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
        guard let cell = gesture.view as? PhotoCell else { return }
        if let indexPath = collectionView?.indexPath(for: cell) {
            deletePhotoAt(indexPath: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let image = images[indexPath.item]
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        if UIDevice.current.orientation.isLandscape {
            if image.size.width < image.size.height {
                // picture is potrait
                height = image.size.width / image.size.height * view.frame.width + 80
                width = (image.size.width - view.frame.width) / image.size.height * view.frame.width
                
            } else {
                // picture is landscape
                width = view.frame.width
                height = image.size.height / image.size.width * width
            }
            
        } else {
            width = view.frame.width
            if image.size.width < image.size.height {
                //                height = view.frame.height / 2 - 40
                height = view.frame.height / 2
                
            } else {
                // landscape
                height = image.size.height / image.size.width * width
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
    var isFetchingPhotos: Bool = false
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if Int(scrollView.contentOffset.y) >= Int((scrollView.contentSize.height - scrollView.frame.size.height)) {
            if reachedBottomOfPhotos {
                print("reached end of photos")
                return
            }
            
            fetchMorePhotos()
        }
        
        if (scrollView.contentOffset.y <= 0.0){
            addPhotoToTopOfStack()
        }
    }
    
    
    
    
    
}
