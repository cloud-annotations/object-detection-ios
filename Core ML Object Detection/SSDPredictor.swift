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
    
    func predict(_ image: CVImageBuffer, orientation: CGImagePropertyOrientation, completion: @escaping ([VNRecognizedObjectObservation]?, Error?) -> Void) {
//        self.semaphore.wait()
        DispatchQueue.global(qos: .userInitiated).async {
//            self.semaphore.wait()
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
//                defer { self.semaphore.signal() }
                request.imageCropAndScaleOption = .scaleFill
                
                let requestOptions: [VNImageOption: Any] = [:]
                let requestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: orientation, options: requestOptions)
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

