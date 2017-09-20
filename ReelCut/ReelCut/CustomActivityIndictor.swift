//
//  CustomActivityIndictor.swift
//  ReelCut
//
//  Created by Francisco Arrieta on 9/9/17.
//  Copyright © 2017 Francisco Arrieta. All rights reserved.
//

import Foundation
import UIKit

class CustomActivityIndictorView {
    
    var imageView: UIImageView?
    var isAnimating: Bool = true

    init(imageView: UIImageView) {
        self.imageView = imageView
    }
    
    func startAnimating() {
        guard let imageView = self.imageView else {
            return
        }
        
        isAnimating = true
        rotateViewIndefinitely(targetView: imageView)
    }
    
    func stopAnimating() {
        isAnimating = false
    }
    
    private func rotateViewIndefinitely(targetView: UIView, duration: Double = 1.0) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            targetView.transform = targetView.transform.rotated(by: CGFloat.pi)
        }) { finished in
            
            if self.isAnimating {
                print("here i am")
                self.rotateViewIndefinitely(targetView: targetView, duration: duration)
            }
        }
    }
    
    
    
    
}
