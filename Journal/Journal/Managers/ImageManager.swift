//
//  ImageManager.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

import Foundation
import UIKit
import CoreLocation


public class ImageManager {
    
    //
    // MARK: - Member Variables
    //
    public static let sharedInstance = ImageManager()
    private init() {}
    
    /// Create a smaller version of the image to show in the tables or lists
    /// - Parameter image: An `UIImage`
    /// - Returns: An `UIImage?`
    func createThumbnail(image: UIImage) -> UIImage? {
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 100] as CFDictionary // Specify your desired size at kCGImageSourceThumbnailMaxPixelSize.
        
        guard let imageData = image.pngData(),
              let imageSource = CGImageSourceCreateWithData(imageData as NSData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
        else {
            return nil
        }
        return UIImage(cgImage: image)
    }
    
    /// Returns a `UIImage` with a given name from the Documents directory
    /// - Parameter imageName: A `String` filename
    /// - Parameter thumbnail: A `Bool` to indicate the thumbnail or full size
    /// - Returns: An `UIImage?`
    func getImage(_ imageName: String, thumbnail: Bool) -> UIImage? {
        var name = imageName
        if thumbnail {
            name = imageName.replacingOccurrences(of: "jpeg", with: "thumbnail.jpeg")
        }
        print(name)
        let url = LocalStorageManager.sharedInstance.getDocumentsURL().appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: url.path) {
            print("Get: \(url)")
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }
    
    
    /// Copy an image (from picker selection) to local documents directory. Use the UUID as
    /// the name of the file, which will correspond to
    func copyImageToDocumentsDirectory(image: UIImage, uuid: UUID) -> String {
        
        // Compress and then save
        if let data = image.jpegData(compressionQuality: 0.5) {
            let imagePath = getDocumentsURL()
                .appendingPathComponent(uuid.uuidString).appendingPathExtension("jpeg")
            try? data.write(to: imagePath)
        }
        
        // Create a thumbnail
        if let thumbnailImage = createThumbnail(image: image) {
            if let data = thumbnailImage.jpegData(compressionQuality: 0.5) {
                let imagePath = getDocumentsURL()
                    .appendingPathComponent(uuid.uuidString).appendingPathExtension("thumbnail.jpeg")
                try? data.write(to: imagePath)
            }
        }
        
        return uuid.uuidString.appending(".jpeg")
    }
    
    
    /// Delete ALL the images in the documents directory that have .jpeg extension
    func  deleteImagesInDocumentsDirectory() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                if fileURL.pathExtension == "jpeg" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  { print(error) }
    }
    
    
    
    //
    // MARK: - Image Metadata
    //
    
    /// Extract the GPS coordinates from a given image
    /// - Parameter imageURL: URL to the local image storage in the documents directory
    /// - Returns: A new `CLLocation` struct with the coordinates; if there are no coordinates found then it returns `0,0`
    func extractCoordinate(imageURL: URL) -> CLLocationCoordinate2D {
        // Try to extract data about the images; this doesn't always work
        if let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil) {
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
            if let dict = imageProperties as? [String : Any] {
                guard let locationInfo = dict["{GPS}"] as? Dictionary<String, Any> else {
                    return CLLocationCoordinate2DMake(0, 0)
                }
                return CLLocationCoordinate2DMake((locationInfo["Latitude"]! as? Double)!,
                                                  (locationInfo["Longitude"]! as? Double)!)
            }
        }
        return CLLocationCoordinate2DMake(0, 0)
    }
    
    
    /// Retrieve the `URL` of the app documents directory
    /// - Returns: The `URL` of the local documents directory
    func getDocumentsURL() -> URL {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        } else {
            fatalError("Could not retrieve documents directory")
        }
    }
    
}
