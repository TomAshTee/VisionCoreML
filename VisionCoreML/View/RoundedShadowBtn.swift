//
//  RoundedShadowBtn.swift
//  VisionCoreML
//
//  Created by Tomasz Jaeschke on 09/03/2019.
//  Copyright © 2019 Tomasz Jaeschke. All rights reserved.
//

import UIKit

class RoundedShadowBtn: UIButton {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowRadius = 0.75
        self.layer.cornerRadius = self.frame.height / 2
    }

}
