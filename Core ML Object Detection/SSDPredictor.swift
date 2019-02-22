//
//  SSDPredictor.swift
//  Core ML Object Detection
//
//  Created by Nicholas Bourdakos on 2/21/19.
//  Copyright © 2019 Nicholas Bourdakos. All rights reserved.
//

import UIKit
import CoreML
import Vision

class SSDPredictor {
    let semaphore = DispatchSemaphore(value: 1)
    let classifier: VNCoreMLModel?
    
    init(_ model: MLModel) {
        classifier = try? VNCoreMLModel(for: model)
    }
    
    func predict(_ image: CVImageBuffer, completion: @escaping ([VNRecognizedObjectObservation]?, Error?) -> Void) {
        self.semaphore.wait()
        DispatchQueue.global(qos: .userInitiated).async {
            guard let classifier = self.classifier else {
                let description = "Predictor failed to load"
                let userInfo = [NSLocalizedDescriptionKey: description]
                let error = NSError(domain: Bundle.main.bundleIdentifier ?? "", code: 0, userInfo: userInfo)
                completion(nil, error)
                return
            }
            let request = VNCoreMLRequest(model: classifier) { request, error in
                if let error = error {
                    let description = error.localizedDescription
                    let userInfo = [NSLocalizedDescriptionKey: description]
                    let error = NSError(domain: Bundle.main.bundleIdentifier ?? "", code: 0, userInfo: userInfo)
                    completion(nil, error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    let description = "could not load model"
                    let userInfo = [NSLocalizedDescriptionKey: description]
                    let error = NSError(domain: Bundle.main.bundleIdentifier ?? "", code: 0, userInfo: userInfo)
                    completion(nil, error)
                    return
                }
                completion(observations, nil)
            }
            
            do {
                defer { self.semaphore.signal() }
                request.imageCropAndScaleOption = .scaleFill
                
                let requestOptions: [VNImageOption: Any] = [:]
                let orientation = CGImagePropertyOrientation(rawValue: UInt32(EXIFOrientation.rightTop.rawValue))
                let requestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: orientation!, options: requestOptions)
                try requestHandler.perform([request])
            } catch {
                let description = "Failed to process classification request: \(error.localizedDescription)"
                let userInfo = [NSLocalizedDescriptionKey: description]
                let error = NSError(domain: Bundle.main.bundleIdentifier ?? "", code: 0, userInfo: userInfo)
                completion(nil, error)
                return
            }
        }
    }
}

enum EXIFOrientation: Int32 {
    case topLeft = 1
    case topRight
    case bottomRight
    case bottomLeft
    case leftTop
    case rightTop
    case rightBottom
    case leftBottom
    
    var isReflect:Bool {
        switch self {
        case .topLeft,.bottomRight,.rightTop,.leftBottom: return false
        default: return true
        }
    }
}

