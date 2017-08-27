//
//  Extensions.swift
//  ReelCut
//
//  Created by Francisco Arrieta on 8/26/17.
//  Copyright © 2017 Francisco Arrieta. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
