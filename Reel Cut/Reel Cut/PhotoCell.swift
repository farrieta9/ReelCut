//
//  PhotoCell.swift
//  Reel Cut
//
//  Created by Francisco Arrieta on 8/11/16.
//  Copyright © 2016 lil9porkchop. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
	
	let thumbnailImageView: UIImageView	= {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		//		imageView.contentMode = .ScaleToFill
		imageView.contentMode = UIViewContentMode.ScaleAspectFit
		return imageView
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setUpView()
	}
	
	func setUpView() {
		addSubview(thumbnailImageView)
		
		// need x, y, width, and height
		thumbnailImageView.centerXAnchor.constraintEqualToAnchor(self.centerXAnchor).active = true
		thumbnailImageView.centerYAnchor.constraintEqualToAnchor(self.centerYAnchor).active = true
		thumbnailImageView.widthAnchor.constraintEqualToAnchor(self.widthAnchor, constant: -8).active = true
		thumbnailImageView.heightAnchor.constraintEqualToAnchor(self.heightAnchor, constant: -8).active = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


