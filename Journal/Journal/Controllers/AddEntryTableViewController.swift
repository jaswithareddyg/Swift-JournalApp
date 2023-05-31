//
//  AddEntryTableViewController.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

// TODO: Add editing features that allows a current entry to be edited

import UIKit
import Photos
import CoreLocation

class AddEntryTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    //
    // MARK: - Variables
    //
    var imageURL: URL?
    var coordinates: CLLocationCoordinate2D?
    var localImagePath: String?
    var tags: [String]?
    
    //
    // MARK: - IBOutlets
    //
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var createdDate: UIDatePicker!
    //
    // MARK: - IBActions
    //

    
    /// Save the journal entry being edited on the form
    @IBAction func tapSave(_ sender: Any) {

        let uuid = UUID()
        if let image = imageView.image {
            self.localImagePath = ImageManager.sharedInstance.copyImageToDocumentsDirectory(image: image, uuid: uuid)
        }

        // Create a new journal entry
        let entry = Journal(uuid: uuid, synced: false, note: textView.text, imageName: localImagePath, createdDate: Date(),
                            cloudKitRecordId: nil, cloudKitChangeTag: nil,
                            date: createdDate.date, latitude: coordinates?.latitude, longitude: coordinates?.longitude, tags: tags)
        
    
        // Add to local data storage
        LocalStorageManager.sharedInstance.journals.append(entry)
        LocalStorageManager.sharedInstance.saveJournalToDisk()
        
        // Sync
        CloudKitManager.sharedInstance.syncLocalToCloudKit()
        
        // Reload the table on the presenting table view controller
        let pvc = self.presentingViewController as! UINavigationController
        let jvc = pvc.topViewController as! JournalTableViewController
        jvc.reloadDataAndTable()

        // Dismiss
        self.presentingViewController?.dismiss(animated: true,
                                               completion: nil)
    }
    
    /// Show the system image picker
    @IBAction func tapSelectImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        picker.sourceType = .photoLibrary  // Set the source type to the photo library
        present(picker, animated: true)
    }
    
    //
    // MARK: - Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        // Show the keyboard on launch
        textView.becomeFirstResponder()
        tableView.keyboardDismissMode = .onDrag
    }
    
}

extension  AddEntryTableViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        coordinates = ImageManager.sharedInstance.extractCoordinate(imageURL: info[.imageURL] as! URL)
        /*
        // M1 macs have an issue with VisionFramework
        #if targetEnvironment(simulator)
         tags = ["sample-dog","sample-flower"]
        #else
         // Vision Framework
         LabelRecognizerManager.detectObjectsWithVision(image: image) { tags in
            self.tags = tags

            // Update the image on the view controller
            self.imageView.image = image

            // Dismiss the picker
            self.dismiss(animated: true)
        }
         
         
        #endif
        */
        
        #if targetEnvironment(simulator)
            tags = ["sample-dog","sample-flower"]
        #else
            tags = LabelRecognizerManager.detectObjectsWithApple(image: image)
        #endif
        
        // Update the image on the view controller
        imageView.image = image
        
        // Dismiss the picker
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user cancels
        dismiss(animated: true)
    }
}
