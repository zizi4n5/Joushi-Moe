//
//  Extensions.swift
//  Joushi-Moe
//
//  Created by zizi on 2017/10/21.
//  Copyright © 2017年 zizi. All rights reserved.
//

import Foundation
import UIKit

func * (lhs: CGRect, rhs: CGFloat) -> CGRect {
    
    let x = lhs.origin.x - (lhs.width * rhs - lhs.width) / 2.0
    let y = lhs.origin.y - (lhs.height * rhs - lhs.height) / 2.0
    let width = lhs.width * rhs
    let height = lhs.height * rhs
    return CGRect(x: x, y: y, width: width, height: height)
}
