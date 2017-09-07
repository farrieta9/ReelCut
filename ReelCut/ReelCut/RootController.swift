//
//  MainController.swift
//  ReelCut
//
//  Created by Francisco Arrieta on 6/5/17.
//  Copyright © 2017 Francisco Arrieta. All rights reserved.
//

import UIKit
import Photos

class RootController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var didFinishRotatingAppIcon: Bool = false
    private let swipeDirections: [UISwipeGestureRecognizerDirection] = [.right, .left]
    private let firstOpen = "firstOpen"
    var shouldScrollToItem: Bool = false
    var isViewingPhoto: Bool = false
    var timer: Timer? = nil
    var startingFrame: CGRect?
    var blackBackGroundView: UIView?
    var startingImageView: UIImageView?
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
    
    let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.clipsToBounds = true
        view.activityIndicatorViewStyle = .whiteLarge
        view.hidesWhenStopped = true
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        return view
    }()
    
    let reelCutImageView: UIImageView = {
//        let renderingMode = UIImageRenderingMode.alwaysOriginal
//        let image = UIImage(named: "reelcut-512x512")?.withRenderingMode(renderingMode)
//        image = image?.imageRendererFormat
//        image = image.imageWithRenderingMode(.AlwaysTemplate)
        
//        image = image?.withRenderingMode(renderingMode)
        let image = UIImage(named: "reelcut-512x512")
        let iv = UIImageView(image: image)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
//        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.init(r: 1.0, g: 0, b: 0, alpha: 0.5)
        return iv
    }()
    
    func rotateAppIcon(duration: CFTimeInterval = 2.0) {
        
        if didFinishRotatingAppIcon {
            return
        }
        
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * duration)
        rotateAnimation.duration = duration
        
        reelCutImageView.layer.add(rotateAnimation, forKey: nil)
    }
    
    var startIndex: Int = 0
    var endIndex: Int = 30
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard let collectionView = collectionView else { return }
        rotateAppIcon()
        collectionView.backgroundColor = .white
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: cellId)
        
//        view.addSubview(reelCutImageView)
        view.addSubview(permissionLabel)
        view.addSubview(loadingIndicator)
        
        // x, y, width, height
//        reelCutImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        reelCutImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
////        reelCutImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
//        reelCutImageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        reelCutImageView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loadingIndicator.widthAnchor.constraint(equalToConstant: 64).isActive = true
        loadingIndicator.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
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
    
    func performZoomInForStartingImageView(startingImageView: UIImageView) {
        
        if isViewingPhoto { return }
        
        isViewingPhoto = true
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        let zoomingImageView = UIImageView(frame: startingFrame!)
        
        if let selectedImage = startingImageView.image {
            if let index = self.images.index(of: selectedImage) {
                print("Selected image at index: \(index)")
                let selectedAsset = assets[index]
                
                // request a bigger image
                let imageManager = PHImageManager.default()
                let targetSize = CGSize(width: 600, height: 600)
                
                imageManager.requestImage(for: selectedAsset, targetSize: targetSize, contentMode: .aspectFit, options: nil, resultHandler: { (image, info) in
                    zoomingImageView.image = image
                })
            }
        }
        
//        zoomingImageView.image = startingImageView.image
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
            let targetSize = CGSize(width: 350, height: 350)
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
//            self.loadingIndicator.stopAnimating()
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
                self.loadingIndicator.startAnimating()
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
        let targetSize = CGSize(width: 350, height: 350)
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        
        imageManager.requestImage(for: allPhotos[startIndex], targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image, info) in
            
            if let image = image {
                self.images.insert(image, at: 0)
                self.assets.insert(allPhotos[self.startIndex], at: 0)
                
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView?.insertItems(at: [indexPath])
            }
        })
    }
    
    func fetchMorePhotos() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (timer) in
            self.shouldScrollToItem = true
            self.beginLoadingAnimation()
        })
    }
    
    func beginLoadingAnimation() {
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackGroundView = UIView(frame: keyWindow.frame)
            blackBackGroundView?.backgroundColor = .black
            blackBackGroundView?.alpha = 0
            keyWindow.addSubview(blackBackGroundView!)

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
                
                self.blackBackGroundView?.alpha = 0.25
                
            }, completion: { (completed: Bool) in
                self.loadingIndicator.startAnimating()
                
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
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.blackBackGroundView?.alpha = 0
        }) { (completed: Bool) in
            self.loadingIndicator.stopAnimating()
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
    
    func handleSwipe(gesture: UISwipeGestureRecognizer) {
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

