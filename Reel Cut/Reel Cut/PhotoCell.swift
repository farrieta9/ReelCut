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
		imageView.contentMode = UIViewContentMode.scaleAspectFit
		return imageView
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setUpView()
	}
	
	func setUpView() {
		addSubview(thumbnailImageView)
		
		// need x, y, width, and height
		thumbnailImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
		thumbnailImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
		thumbnailImageView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -8).isActive = true
		thumbnailImageView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -8).isActive = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


