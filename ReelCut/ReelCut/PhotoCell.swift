//
//  PhotoCell.swift
//  ReelCut
//
//  Created by Francisco Arrieta on 6/16/17.
//  Copyright © 2017 Francisco Arrieta. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleZoomTap)))
        return iv
    }()
    
    var parentController: RootController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        if let imageView = tapGesture.view as? UIImageView {
            self.parentController?.performZoomInForStartingImageView(startingImageView: imageView)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
