//
//  ViewController.swift
//  Core ML Object Detection
//
//  Created by Nicholas Bourdakos on 2/21/19.
//  Copyright © 2019 Nicholas Bourdakos. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation
import Accelerate

class CameraViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var cameraView: UIView!
    
    // MARK: - Variable Declarations
    
    let ssdPredictor = SSDPredictor(Model().model)
    var boundingBoxes: [UIBoundingBox] = []
    var screenHeight: CGFloat?
    var screenWidth: CGFloat?
    var videoHeight: Int32?
    var videoWidth: Int32?
    
    let videoOutput = AVCaptureVideoDataOutput()
    lazy var captureSession: AVCaptureSession? = {
        guard let backCamera = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: backCamera) else {
                return nil
        }
        
        let dimensions = CMVideoFormatDescriptionGetDimensions(backCamera.activeFormat.formatDescription)
        videoHeight = dimensions.height
        videoWidth = dimensions.width
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        captureSession.addInput(input)
        
        if captureSession.canAddOutput(videoOutput) {
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
            captureSession.addOutput(videoOutput)
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = CGRect(x: view.bounds.minX, y: view.bounds.minY, width: view.bounds.width, height: view.bounds.height)
            // `.resize` allows the camera to fill the screen on the iPhone X.
            previewLayer.videoGravity = .resize
            previewLayer.connection?.videoOrientation = .portrait
            cameraView.layer.addSublayer(previewLayer)
            return captureSession
        }
        return nil
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession?.startRunning()
        screenWidth = view.bounds.width
        screenHeight = view.bounds.height
        for _ in 0 ..< 20 {
            let box = UIBoundingBox()
            box.addToLayer(view.layer)
            boundingBoxes.append(box)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        ssdPredictor.predict(pixelBuffer) { predictions, error in
            guard let predictions = predictions else {
                return
            }
            DispatchQueue.main.async {
                guard let screenWidth = self.screenWidth, let screenHeight = self.screenHeight, let videoWidth = self.videoWidth, let videoHeight =  self.videoHeight else {
                    return
                }
                let topKPredictions = predictions.prefix(self.boundingBoxes.count)
                for (index, prediction) in topKPredictions.enumerated() {
                    guard let label = prediction.labels.first else {
                        return
                    }
                    
                    let width = screenWidth
                    let height = width * (CGFloat(videoWidth) / CGFloat(videoHeight))
                    let offsetY = (screenHeight - height) / 2
                    let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height - offsetY)
                    let rect = prediction.boundingBox.applying(scale).applying(transform)
                    
                    let color = UIColor(red: 36/255, green: 101/255, blue: 255/255, alpha: 1.0)
                    self.boundingBoxes[index].show(frame: rect, label: label.identifier, color: color)
                }
                for index in topKPredictions.count ..< 20 {
                    self.boundingBoxes[index].hide()
                }
            }
        }
    }
}

