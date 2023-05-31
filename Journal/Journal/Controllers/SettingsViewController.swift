//
//  SettingsViewController.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

import UIKit
import CloudKit
import LocalAuthentication
import UserNotifications

class SettingsViewController: UITableViewController {
    
    //
    // MARK: - IBOutlets
    //
    @IBOutlet weak var nameLabel: UILabel!
    
    //
    // MARK: - Instance Variables
    //
    
    /// Current user's record id; we need this to get their name
    var userRecordID: CKRecord.ID?
    
    /// User's name from iCloud
    var userName: String = "" {
        didSet {
            nameLabel.text = self.userName
        }
    }
    
    //
    // MARK: - Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //TODO: Download the user name from cloud kit, store it, and display it
        loadUserName()
    }
    
    @IBAction func toggleTouchId(_ sender: UISwitch) {
        let context = LAContext()
        var error: NSError?
        
        // Check if the device supports biometric authentication (Touch ID or Face ID)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your data"
            
            // Perform biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Authentication succeeded
                        self.performSync()
                    } else {
                        // Authentication failed
                        if let error = error {
                            print("Authentication failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            // Biometric authentication not available or not configured
            if let error = error {
                print("Biometric authentication not available: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func toggleFaceId(_ sender: UISwitch) {
        let context = LAContext()
        var error: NSError?
        
        // Check if the device supports biometric authentication (Touch ID or Face ID)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate with Touch ID to access your data"
            
            // Perform biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Authentication succeeded
                        self.performSync()
                    } else {
                        // Authentication failed
                        if let error = error {
                            print("Authentication failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            // Biometric authentication not available or not configured
            if let error = error {
                print("Biometric authentication not available: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func tapDeleteLocal(_ sender: UIButton) {
        LocalStorageManager.sharedInstance.deleteJournal()
    }
    
    @IBAction func tapSyncWithCloudKit(_ sender: UIButton) {
        //TODO: Implement sync with CloudKit
        CloudKitManager.sharedInstance.syncLocalFromCloudKit()
    }

    @IBAction func toggleOnThisDay(_ sender: UISwitch) {
        //TODO: Add local notification
        if sender.isOn {
            // Schedule a daily local notification
            scheduleDailyNotification()
        } else {
            // Cancel the previously scheduled notification request
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["OnThisDayNotification"])
        }
    }
    
    @IBAction func tapDeleteCloudKit(_ sender: UIButton) {
        if let userRecordID = userRecordID {
            CloudKitManager.sharedInstance.deleteAllJournals(forUser: userRecordID, andLocal: true)
        }
    }
    
    func loadUserName() {
        // Get the user icloud account based on their signed in Apple Id
        CloudKitManager.sharedInstance.getUserRecordId { (recordID, error) in
            
            if let userID = recordID?.recordName {
                print("😀 iCloudID: \(userID)")
                self.userRecordID = recordID
                
                // Get user's name now that we have their icloud acccount id
                // We are nesting this because we have to wait for the record to
                // return before we can send it out for the name
                CloudKitManager.sharedInstance.getUserIdentity(userRecordID: self.userRecordID,
                                                               complete: { (record, error) in
                                                                DispatchQueue.main.async {
                                                                    self.userName = record!.description
                                                                }
                                                               }
                )
            } else {
                print("😢 We could not get the user's record id. iCloudID = nil")
            }
        }

    }
    
    func performSync() {
        CloudKitManager.sharedInstance.syncLocalToCloudKit()
        
        // Reload data in the table view
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        print("Sync completed successfully")
    }

    
    func scheduleDailyNotification() {
        // Create a notification content
        let content = UNMutableNotificationContent()
        content.title = "On This Day"
        content.body = "Don't forget to check your memories!"
        content.sound = .default
        
        // Configure the notification trigger for daily repeating
        var dateComponents = DateComponents()
        dateComponents.hour = 9 // Set the hour when you want to trigger the notification
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create a notification request
        let request = UNNotificationRequest(identifier: "OnThisDayNotification", content: content, trigger: trigger)
        
        // Add the notification request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule local notification: \(error.localizedDescription)")
            }
        }
    }
}
