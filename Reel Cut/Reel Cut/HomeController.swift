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
	
	private let cellId = "cellId"
	var gallery: [UIImage] = [UIImage]()
	var end: Int = 1
	var count = 0
	var reachedEndOfPhotos: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		fetchPhotosFromLibrary(10)
		
		collectionView?.backgroundColor = UIColor.whiteColor()
		collectionView?.registerClass(PhotoCell.self, forCellWithReuseIdentifier: cellId)
		setUpIndicator()
	}
	
	let indicator: UIActivityIndicatorView = {
		let view = UIActivityIndicatorView()
		view.clipsToBounds = true
		view.activityIndicatorViewStyle = .WhiteLarge
		view.hidesWhenStopped = true
		view.backgroundColor = UIColor(white: 0, alpha: 0.7)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.layer.cornerRadius = 10
		return view
	}()
	
	func setUpIndicator() {
		self.view.addSubview(indicator)
		
		// x, y, width, height
		indicator.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
		indicator.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
		indicator.widthAnchor.constraintEqualToConstant(64).active = true
		indicator.heightAnchor.constraintEqualToConstant(64).active = true
		
	}
	
	private func deletePhotoAtIndex(index: Int, cell: PhotoCell) {
		let fetchOptions: PHFetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
		let assetToDelete: PHAsset = fetchResult[index] as! PHAsset
		let arrayToDelete = NSArray(object: assetToDelete)
		
		PHPhotoLibrary.sharedPhotoLibrary().performChanges({
			PHAssetChangeRequest.deleteAssets(arrayToDelete)
		}) { (success, error) in
			if error != nil {
				print(error)  // Clicked Don't Allow
			} else {
				dispatch_async(dispatch_get_main_queue(), {
					if let indexPath = self.collectionView?.indexPathForCell(cell) {
						self.gallery.removeAtIndex(indexPath.item)
						self.collectionView?.deleteItemsAtIndexPaths([indexPath])
					}
				})
			}
		}
	}
	
	func fetchPhotosFromLibrary(number: Int = 20) {
		if reachedEndOfPhotos == true {
			indicator.stopAnimating()
			return
		}
		
		indicator.startAnimating()
		dispatch_async(dispatch_get_main_queue()) {
			
			let imageManager = PHImageManager()
			let requestOptions = PHImageRequestOptions()
			let fetchOptions = PHFetchOptions()
			
			requestOptions.synchronous = true
			requestOptions.deliveryMode = .HighQualityFormat
			
			// ascending false to show the most recent photos first
			fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
			
			guard let assets: PHFetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: fetchOptions) else {
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
				imageManager.requestImageForAsset(assets[i] as! PHAsset, targetSize: self.view.frame.size, contentMode: .AspectFill, options: requestOptions, resultHandler: { (image, _) in
					if let picture = image {
						self.gallery.append(picture)
					}
				})
			}
			self.collectionView!.reloadData()
			self.indicator.stopAnimating()
		}
	}
	
	func handleSwipe(sender: UISwipeGestureRecognizer) {
		guard let cell = sender.view as? PhotoCell, index = collectionView?.indexPathForCell(cell)!.item else {
			return
		}
		
		let position = index + (end - 20)
		deletePhotoAtIndex(position, cell: cell)
	}
}

extension HomeController {
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return gallery.count
	}
	
	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath) as! PhotoCell
		
		cell.thumbnailImageView.image = gallery[indexPath.item]
		
		// Add gestures
		let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
		swipeRight.direction = .Right
		cell.addGestureRecognizer(swipeRight)
		
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return CGSizeMake(view.frame.width, view.frame.height / 2 - 40)
	}
	
	override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	
	override func scrollViewDidScroll(scrollView: UIScrollView) {
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





