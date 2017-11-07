//
//  PhotoCell.swift
//  ReelCut
//
//  Created by Francisco Arrieta on 6/16/17.
//  Copyright © 2017 Francisco Arrieta. All rights reserved.
//

import UIKit
import PhotosUI

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
    
    let hdrLabel: UILabel = {
        let label = UILabel()
        label.text = "HDR"
        label.isHidden = true
        label.textColor = UIColor.init(r: 100, g: 100, b: 100)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var parentController: RootController?
    
    var asset: PHAsset? = nil {
        didSet {
            hdrLabel.isHidden = true
            if let asset = asset {
                if asset.mediaSubtypes.contains(PHAssetMediaSubtype.photoHDR) {
                    hdrLabel.isHidden = false
                }
                
//                if let photoAsset = livePhotoAsset {
//                    PHImageManager.default().requestLivePhoto(for: photoAsset, targetSize: photoView.frame.size, contentMode: .aspectFit, options: nil, resultHandler: { (photo: PHLivePhoto?, info: [AnyHashable : Any]?) in
//
//                        if let livePhoto = photo {
//                            self.photoView.livePhoto = livePhoto
//                            self.photoView.startPlayback(with: .hint)
//                        }
//                    })
//                }
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(hdrLabel)
        
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        hdrLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
        hdrLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 4).isActive = true
    }
    
    @objc func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        guard let asset = asset else { return }
        
        if let imageView = tapGesture.view as? UIImageView {
            self.parentController?.performZoomInForStartingImageView(startingImageView: imageView, asset: asset)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

