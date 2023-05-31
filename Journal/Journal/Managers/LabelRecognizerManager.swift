//
//  LabelRecognizer.swift
//
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

import UIKit
import Vision

public class LabelRecognizerManager {
    
    public static func detectObjectsWithVision(image: UIImage, completion: @escaping ([String]) -> Void) {
        var tags = [String]()
        
        guard let ciImage = CIImage(image: image) else {
            print("Can't convert image to CIImage")
            completion(tags)
            return
        }
        
        guard let model = try? VNCoreMLModel(for: YOLOv3().model) else {
            print("Failed to load Core ML model")
            completion(tags)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                print("Object recognition failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(tags)
                return
            }
            
            for result in results {
                tags.append(result.identifier)
                print("Object: \(result.identifier), Confidence: \(result.confidence)")
            }
            
            completion(tags)
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Object recognition failed: \(error.localizedDescription)")
            completion(tags)
        }
    }
}
