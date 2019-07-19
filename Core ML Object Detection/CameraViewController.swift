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

let DEFAULT_CAMERA_POSITION: AVCaptureDevice.Position = .front
let MAX_BOXES: Int = 20

class CameraViewController: UIViewController {
    var array = [true, false]
    var up = 1
    var down = 1
    let upLayer = CAShapeLayer()
    let downLayer = CAShapeLayer()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var debugImage: UIImageView!
    @IBOutlet weak var upImage: UIImageView!
    @IBOutlet weak var downImage: UIImageView!
    
    // MARK: - Variable Declarations
    
    let ssdPredictor = SSDPredictor(Model().model)
    var boundingBoxOverlay: CALayer!
    var videoSize: CGSize = .zero
    
    let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    let modelInferenceQueue = DispatchQueue(label: "ModelInference", qos: .userInitiated)
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer! = {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // `.resize` allows the camera to fill the screen on the iPhone X.
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }()
    
    let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: DEFAULT_CAMERA_POSITION).devices.first
    
    lazy var captureSession: AVCaptureSession = {
        let captureSession = AVCaptureSession()
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        captureSession.sessionPreset = .vga640x480 // Model image size is smaller.
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice!)
            captureSession.addInput(videoDeviceInput)
        } catch {
            print("Could not create video device input: \(error)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        }
        return captureSession
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
        
        previewLayer?.frame = view.bounds
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            previewLayer?.connection?.videoOrientation = .landscapeLeft
        case .landscapeRight:
            previewLayer?.connection?.videoOrientation = .landscapeRight
        case .portrait:
            previewLayer?.connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            previewLayer?.connection?.videoOrientation = .portraitUpsideDown
        case .unknown:
            previewLayer?.connection?.videoOrientation = .landscapeRight
        }
        do {
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions(videoDevice!.activeFormat.formatDescription)
            videoSize.width = CGFloat(dimensions.width)
            videoSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        
        boundingBoxOverlay = CALayer()
        boundingBoxOverlay.bounds = CGRect(x: 0.0, y: 0.0, width: videoSize.width, height: videoSize.height)
        boundingBoxOverlay.position = CGPoint(x: view.layer.bounds.midX, y: view.layer.bounds.midY)
        view.layer.addSublayer(boundingBoxOverlay)
        
//        let total = self.array.count
//        let up = self.array.filter{ $0 }.count
//        let down = total - up
        
        let total = self.up + self.down
        let up = self.up
        let down = self.down
        
        let upPercent: CGFloat = CGFloat(up) / CGFloat(total)
        let downPercent: CGFloat = CGFloat(down) / CGFloat(total)
        
        let totalViewWidth = view.bounds.width - 64 - 64
        
        let upWidth = upPercent * totalViewWidth
        let downWidth = downPercent * totalViewWidth
        
        upLayer.path = UIBezierPath(roundedRect: CGRect(x: 64, y: 120, width: upWidth, height: 64), cornerRadius: 0).cgPath
        upLayer.fillColor = UIColor.green.cgColor
        
        downLayer.path = UIBezierPath(roundedRect: CGRect(x: view.bounds.width - 64 - downWidth, y: 120, width: downWidth, height: 64), cornerRadius: 0).cgPath
        downLayer.fillColor = UIColor.red.cgColor
        
        view.layer.addSublayer(upLayer)
        view.layer.addSublayer(downLayer)
        view.bringSubviewToFront(upImage)
        view.bringSubviewToFront(downImage)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            let deltaTransform = coordinator.targetTransform
            let deltaAngle = atan2f(Float(deltaTransform.b), Float(deltaTransform.a))
            var currentRotation: Float = (self.cameraView.layer.value(forKeyPath: "transform.rotation.z") as? NSNumber)?.floatValue ?? 0.0
            // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
            currentRotation += -1 * deltaAngle + 0.0001;
            self.cameraView.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
            self.cameraView.layer.frame = self.view.bounds
        }) { (UIViewControllerTransitionCoordinatorContext) in
            // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
            var currentTransform: CGAffineTransform = self.cameraView.transform
            currentTransform.a = round(currentTransform.a)
            currentTransform.b = round(currentTransform.b)
            currentTransform.c = round(currentTransform.c)
            currentTransform.d = round(currentTransform.d)
            self.cameraView.transform = currentTransform
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        DispatchQueue.main.async {
            // Get a debug image.
//            let ciimage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
//            let context: CIContext = CIContext.init(options: nil)
//            let cgImage: CGImage = context.createCGImage(ciimage, from: ciimage.extent)!
//            let image: UIImage = UIImage.init(cgImage: cgImage)
//            self.debugImage.image = image
           //
        
            let exifOrientation: CGImagePropertyOrientation
            
            switch UIApplication.shared.statusBarOrientation {
            case .portrait:
                exifOrientation = .right
            case .landscapeRight:
                exifOrientation = .down
            case .portraitUpsideDown:
                exifOrientation = .left
            case .landscapeLeft:
                exifOrientation = .up
            case .unknown:
                exifOrientation = .up
            }
    
            self.ssdPredictor.predict(pixelBuffer, orientation: exifOrientation) { predictions, error in
                guard let predictions = predictions else {
                    return
                }
                DispatchQueue.main.async {
                    CATransaction.begin()
                    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                    self.boundingBoxOverlay.sublayers = nil

                    let realWidthLayerDim = fmax(self.view.layer.bounds.size.width, self.view.layer.bounds.size.height)
                    let realWidthVideoDim = fmax(self.videoSize.width, self.videoSize.height)

                    let realHeightLayerDim = fmin(self.view.layer.bounds.size.width, self.view.layer.bounds.size.height)
                    let realHeightVideoDim = fmin(self.videoSize.width, self.videoSize.height)

                    let xScale: CGFloat = realWidthLayerDim / realWidthVideoDim
                    let yScale: CGFloat = realHeightLayerDim / realHeightVideoDim

                    var scale = fmax(xScale, yScale)
                    if scale.isInfinite {
                        scale = 1.0
                    }

                    let topKPredictions = predictions.prefix(MAX_BOXES)
                    for prediction in topKPredictions {
                        guard let label = prediction.labels.first else {
                            return
                        }

                        let objectBounds = VNImageRectForNormalizedRect(prediction.boundingBox, Int(self.videoSize.width), Int(self.videoSize.height))

                        let color = UIColor(red: 36/255, green: 101/255, blue: 255/255, alpha: 1.0)
                        let box = UIBoundingBox()
                        box.addToLayer(self.boundingBoxOverlay)
                        
                        if label.identifier == "up" {
                            self.up = self.up + 1
                            box.show(frame: objectBounds, label: "👍", color: color, scale: scale)
//                            self.array.append(true)
                        } else if label.identifier == "down" {
                            self.down = self.down + 1
                            box.show(frame: objectBounds, label: "👎", color: color, scale: scale)
//                            self.array.append(false)
                        }
                        
//                        if self.array.count > 1000 {
//                            self.array.removeFirst()
//                        }
                    }
                    
//                    let total = self.array.count
//                    let up = self.array.filter{ $0 }.count
//                    let down = total - up

                    let total = self.up + self.down
                    let up = self.up
                    let down = self.down
                    
                    let upPercent: CGFloat = CGFloat(up) / CGFloat(total)
                    let downPercent: CGFloat = CGFloat(down) / CGFloat(total)
                    
                    let totalViewWidth = self.view.bounds.width - 64 - 64
                    
                    let upWidth = upPercent * totalViewWidth
                    let downWidth = downPercent * totalViewWidth
                    
                    self.upLayer.path = UIBezierPath(roundedRect: CGRect(x: 64, y: 120, width: upWidth, height: 64), cornerRadius: 0).cgPath
                    self.downLayer.path = UIBezierPath(roundedRect: CGRect(x: self.view.bounds.width - 64 - downWidth, y: 120, width: downWidth, height: 64), cornerRadius: 0).cgPath

                    CATransaction.begin()
                    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                    // rotate the layer into screen orientation and scale and mirror
                    if exifOrientation == .left || exifOrientation == .right {
                        self.boundingBoxOverlay.setAffineTransform(CGAffineTransform(rotationAngle: 0.0).scaledBy(x: -1.597, y: -2.845))
                    } else {
                        self.boundingBoxOverlay.setAffineTransform(CGAffineTransform(rotationAngle: 0.0).scaledBy(x: -scale, y: -scale))
                    }

                    // center the layer

                    self.boundingBoxOverlay.position = CGPoint(x: self.view.layer.bounds.midX, y: self.view.layer.bounds.midY)
                    CATransaction.commit()
                    CATransaction.commit()
                }
            }
        }
    }
}

