//
//  UIBoundingBox.swift
//  Core ML Object Detection
//
//  Created by Nicholas Bourdakos on 2/21/19.
//  Copyright © 2019 Nicholas Bourdakos. All rights reserved.
//

import UIKit

class UIBoundingBox {
    let shapeLayer: CAShapeLayer
    let textLayer: CATextLayer
    
    init() {
        shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 3
        shapeLayer.isHidden = true
        
        textLayer = CATextLayer()
        textLayer.isHidden = true
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 14
        textLayer.font = UIFont.systemFont(ofSize: textLayer.fontSize)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
    }
    
    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(shapeLayer)
        parent.addSublayer(textLayer)
    }
    
    func show(frame: CGRect, label: String, color: UIColor, textColor: UIColor = .white) {
        CATransaction.setDisableActions(true)
        
        let path = UIBezierPath(roundedRect: frame, cornerRadius: 6.0)
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.isHidden = false
        
        textLayer.string = label
        textLayer.foregroundColor = textColor.cgColor
        textLayer.backgroundColor = color.cgColor
        textLayer.isHidden = false
        
        let attributes = [
            NSAttributedString.Key.font: textLayer.font as Any
        ]
        
        let textRect = label.boundingRect(with: CGSize(width: 400, height: 100), options: .truncatesLastVisibleLine, attributes: attributes, context: nil)
        let textSize = CGSize(width: textRect.width + 6, height: textRect.height)
        let textOrigin = CGPoint(x: frame.origin.x, y: frame.origin.y - textSize.height - 3)
        textLayer.frame = CGRect(origin: textOrigin, size: textSize)
    }
    
    func hide() {
        shapeLayer.isHidden = true
        textLayer.isHidden = true
    }
}

