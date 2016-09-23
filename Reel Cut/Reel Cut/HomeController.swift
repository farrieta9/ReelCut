//
//  ViewController.swift
//  Reel Cut
//
//  Created by Francisco Arrieta on 8/10/16.
//  Copyright © 2016 lil9porkchop. All rights reserved.
//

import UIKit
import Photos

class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	
	fileprivate let cellId = "cellId"
	var gallery: [UIImage] = [UIImage]()
	var end: Int = 1
	var count = 0
	var reachedEndOfPhotos: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		fetchPhotosFromLibrary(10)
		
		collectionView?.backgroundColor = UIColor.white
		collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: cellId)
		setUpIndicator()
	}
	
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
	
	func setUpIndicator() {
		self.view.addSubview(indicator)
		
		// x, y, width, height
		indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		indicator.widthAnchor.constraint(equalToConstant: 64).isActive = true
		indicator.heightAnchor.constraint(equalToConstant: 64).isActive = true
		
	}
	
	fileprivate func deletePhotoAtIndex(_ index: Int, cell: PhotoCell) {
		let fetchOptions: PHFetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
		let assetToDelete: PHAsset = fetchResult[index] 
		let arrayToDelete = NSArray(object: assetToDelete)
		
		PHPhotoLibrary.shared().performChanges({
			PHAssetChangeRequest.deleteAssets(arrayToDelete)
		}) { (success, error) in
			if error != nil {
				print(error)  // Clicked Don't Allow
			} else {
				DispatchQueue.main.async(execute: {
					if let indexPath = self.collectionView?.indexPath(for: cell) {
						self.gallery.remove(at: (indexPath as NSIndexPath).item)
						self.collectionView?.deleteItems(at: [indexPath])
					}
				})
			}
		}
	}
	
	func fetchPhotosFromLibrary(_ number: Int = 20) {
		if reachedEndOfPhotos == true {
			indicator.stopAnimating()
			return
		}
		
		indicator.startAnimating()
		DispatchQueue.main.async {
			
			let imageManager = PHImageManager()
			let requestOptions = PHImageRequestOptions()
			let fetchOptions = PHFetchOptions()
			
			requestOptions.isSynchronous = true
			requestOptions.deliveryMode = .highQualityFormat
			
			// ascending false to show the most recent photos first
			fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
			
			guard let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions) else {
				return
			}

			var start: Int = 0
//			if assets.count < 1 {
//				return // User has no photos
//			}
//			
//			
//			// case 2: less than 20 photos
//			if assets.count < 20 {
//				self.end = 20
//				start = 0
//			} else { // case 3: more than 20 photos
//				self.end += 20
//				start = self.end - 20
//			}
//			
//			// case 4 reached the end of photos
//			if self.end > assets.count {
//				print("reached end of gallery. end: \(self.end)")
//				self.reachedEndOfPhotos = true
//				return
//			}
			
			if assets.count < 1 {
				return
			} else if assets.count < 20 {
				self.end = assets.count
				start = 0
			} else if self.end > assets.count {
//				self.end = assets.count
//				start = self.end - 20
				self.reachedEndOfPhotos = true
			} else {
				self.end += 20
				start = self.end - 20
			}
			
			self.gallery = []
			for i in start..<self.end {
				imageManager.requestImage(for: assets[i] , targetSize: self.view.frame.size, contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, _) in
					if let picture = image {
						self.gallery.append(picture)
					}
				})
			}
			self.collectionView!.reloadData()
			self.indicator.stopAnimating()
		}
	}
	
	func handleSwipe(_ sender: UISwipeGestureRecognizer) {
		guard let cell = sender.view as? PhotoCell, let index = collectionView?.indexPath(for: cell)?.item else {
			return
		}
		
		let position = index + (end - 20)
		deletePhotoAtIndex(position, cell: cell)
	}
}

extension HomeController {
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return gallery.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! PhotoCell
		
		cell.thumbnailImageView.image = gallery[(indexPath as NSIndexPath).item]
		
		// Add gestures
		let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
		swipeRight.direction = .right
		cell.addGestureRecognizer(swipeRight)
		
		return cell
	}
	
	@objc(collectionView:layout:sizeForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: view.frame.width, height: view.frame.height / 2 - 40)
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if reachedEndOfPhotos == true {
			return
		}
		
		if (scrollView.contentOffset.y < 0) {
			//reach top
			indicator.stopAnimating()
			return
		}
		
		if (scrollView.contentOffset.y - 50) >= (scrollView.contentSize.height - scrollView.frame.size.height) && (reachedEndOfPhotos == false){
			//bottom reached
//			fetchPhotosFromLibrary()
//			scrollView.setContentOffset(CGPointMake(0, 0), animated: false)
		}
	}
}





