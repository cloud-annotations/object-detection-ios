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
    
    func show(frame: CGRect, label: String, color: UIColor, textColor: UIColor = .white, scale: CGFloat = 1.0) {
        CATransaction.setDisableActions(true)
        
        let fontSize = 1.8 * frame.size.height * (1 / scale)
        
        textLayer.fontSize = fontSize
        shapeLayer.lineWidth = 3 * (1 / scale)
        
        
        let path = UIBezierPath(roundedRect: frame, cornerRadius: 6.0 * (1 / scale))
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.isHidden = false
        
        textLayer.string = label
        textLayer.foregroundColor = textColor.cgColor
//        textLayer.backgroundColor = color.cgColor
        textLayer.isHidden = false
        
        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)
        ]
        
        let textRect = label.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        let textSize = CGSize(width: textRect.width + (6 * (1 / scale)), height: textRect.height)
//        let textOrigin = CGPoint(x: frame.origin.x + frame.size.width - textSize.width, y: frame.origin.y + frame.size.height + (3 * (1 / scale)))
        let textOrigin = CGPoint(x: frame.origin.x + ((frame.size.width - textSize.width) / 2), y: frame.origin.y + ((frame.size.height - textSize.height) / 2))
        textLayer.frame = CGRect(origin: textOrigin, size: textSize)
        
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 1.0)))
    }
    
    func hide() {
        shapeLayer.isHidden = true
        textLayer.isHidden = true
    }
}

