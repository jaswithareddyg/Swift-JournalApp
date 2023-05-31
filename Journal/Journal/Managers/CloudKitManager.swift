//
//  CloudKitManager.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

import Foundation
import CloudKit

open class CloudKitManager {
    
    // Singleton usage
    public static let sharedInstance = CloudKitManager()
    
    
    //
    // MARK: - CloudKit Variables
    //
    
    let container: CKContainer = CKContainer.default()
    let publicDB: CKDatabase = CKContainer.default().publicCloudDatabase
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    
    /// Specify a "currentDB" so it's easy to switch between them (for demonstration purposes)
    let currentDB: CKDatabase = CKContainer.default().publicCloudDatabase
    
    /// Current user's iCloud Record; the id will be stored here
    var userRecordID: CKRecord.ID?
    
    /// Keep track if we have synced to CloudKit
    var synced = false
    
    // Path to locally stored journal data
    var localJournals = LocalStorageManager.sharedInstance.journals
    
    //
    // MARK: - Singleton methods
    //
    private init() {}
    
    
    
    //
    // MARK: - CloudKit User Records
    //
    
    /// Get the user's `RecordId` as assigned by CloudKit. We need this in order to get their name.
    /// - Parameters:
    ///   - complete: A completion block passing two parameters: `CKRecord.ID` and `NSError`
    open func getUserRecordId(complete: @escaping (CKRecord.ID?, NSError?) -> ()) {
        
        // CloudKit function call
        self.container.fetchUserRecordID() { recordID, error in
            
            if let error = error {
                print(error.localizedDescription)
                complete(nil, error as NSError?)
            } else {
                // We have access to the user's record
                print("☁️ fetched ID \(recordID?.recordName ?? "")")
                complete(recordID, nil)
            }
        }
    }
    
    /// Get the user's identity (name).
    /// - Parameters:
    ///   - userRecordID: The user's recordID from CloudKit.
    ///   - complete: A completion block passing two parameters: `String` and `NSError`
    open func getUserIdentity(userRecordID: CKRecord.ID?, complete: @escaping (String?, NSError?) -> ()) {
        // Ask for permission to get name
        self.container.requestApplicationPermission(.userDiscoverability) { (status, error) in
            
            // Query user identity with record id
            self.container.discoverUserIdentity(withUserRecordID: userRecordID!) { (userID, error) in
                if let error = error {
                    print(error.localizedDescription)
                    complete(nil, error as NSError?)
                } else {
                    let userName = (userID?.nameComponents?.givenName ?? "") + " " + (userID?.nameComponents?.familyName ?? "")
                    print("☁️ CloudKit User Name: " + userName)
                    complete(userName, nil)
                }
            }
        }
    }
    
    //
    // MARK: - CRUD (Create, Update, Delete)
    //
    
    /// Create a journal record and save it to iCloud using CloudKit.
    /// - Parameters:
    ///   - journal: The journal object to be saved.
    ///   - complete: A completion block passing a single parameter of type `String`.
    func addJournal(_ journal: Journal, complete: @escaping (String?) -> ()) {
        
        let record = CKRecord(recordType: "journal")
        
        record.setValue(journal.uuid.uuidString, forKey: "uuid")
        record.setValue(journal.date.description, forKey: "date")
        record.setValue(journal.note, forKey: "note")
        if let lat = journal.latitude, let long = journal.longitude {
            record.setValue(CLLocation(latitude: lat, longitude: long), forKey: "location")
        }
        
        currentDB.save(record) { (record, error) in
            if let error = error {
                print("☁️ Error: \(error.localizedDescription)")
                complete(nil)
            } else {
                print("☁️ Saved record: \(record.debugDescription)")
                complete(record?.recordID.recordName)
            }
        }
    }
    
    //
    // MARK: - Syncing
    //
    
    /// Delete all journal records on iCloud.
    /// - Parameters:
    ///   - forUser: The CKRecord.ID of the user whose journals should be deleted.
    ///   - andLocal: A boolean value indicating whether to delete the local data as well.
    func deleteAllJournals(forUser: CKRecord.ID, andLocal: Bool) {
        let reference = CKRecord.Reference(recordID: forUser, action: .none)
        let predicate = NSPredicate(format: "creatorUserRecordID == %@", reference)
        let query = CKQuery(recordType: "journal", predicate: predicate)
        
        currentDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error: \(String(describing: error.localizedDescription))")
                return
            }
            
            guard let records = records else {
                return
            }
            
            for record in records {
                print("🗑 Trying To Delete: \(record["note"] as? String ?? "")")
                
                self.currentDB.delete(withRecordID: record.recordID) { (recordId, error) in
                    if let error = error {
                        print("☁️ Error: \(error.localizedDescription)")
                    } else {
                        print("☁️ Record deleted: \(recordId?.recordName ?? "")")
                    }
                }
            }
            
            if andLocal {
                LocalStorageManager.sharedInstance.deleteJournal()
            }
        }
    }
    
    /// Iterate through all the local journal entries and check if any are "synced == false"; if not, then upload them.
    func syncLocalToCloudKit() {
        for journal in LocalStorageManager.sharedInstance.journals {
            if journal.synced == false {
                print("Need to Sync: \(journal.uuid)")
                addJournal(journal) { (cloudKitRecordName) in
                    // Need to update the local data now that it is synced
                    // LocalStorageManager.sharedInstance.synced(uuid, recordName)
                }
            }
        }
    }
    
    /// Download all journal records from iCloud and compare them against what is in the local database.
    func syncLocalFromCloudKit() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "journal", predicate: predicate)
        
        currentDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error: \(String(describing: error.localizedDescription))")
                return
            }
            
            guard let records = records else {
                return
            }
            
            for record in records {
                print("You should copy this to the local data: \(record.recordID.recordName)")
            }
        }
    }
    
    //
    // MARK: - Subscriptions
    //
    
    /// Register the journal subscription with CloudKit. We want to be notified of any changes to a `Journal` record.
    func registerSubscription() {
        let uuid = UUID()
        let identifier = "\(uuid)-journal"
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = ["note"]
        notificationInfo.soundName = "default"
        notificationInfo.title = "Database Changed"
        notificationInfo.alertBody = "Go Fetch the Changes"
        
        let subscription = CKQuerySubscription(recordType: "journal",
                                               predicate: NSPredicate(value: true),
                                               subscriptionID: identifier,
                                               options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        subscription.notificationInfo = notificationInfo
        
        CKContainer.default().publicCloudDatabase.save(subscription) { (returnRecord, error) in
            if let error = error {
                print("Journal: subscription failed \(error.localizedDescription)")
            } else {
                print("Journal: subscription set up")
                UserDefaults.standard.setValue(true, forKey: "didCreateQuerySubscription")
            }
        }
    }
}
