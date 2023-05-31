//
//  LocalStorageManager.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

import Foundation

/// Manage the local storage of our Journals
public class LocalStorageManager {
    
    //
    // MARK: - Member Variables
    //
    public static let sharedInstance = LocalStorageManager()
    public var journals: [Journal] = []
    
    private init() {
        self.journals = loadJournalFromDisk()
        //print(journals)
    }
    
    //
    // Persist to disk
    //
    
    /// Helper method to get a URL to the user's documents directory
    /// - Returns: A URL to documents director
    func getDocumentsURL() -> URL {
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        } else {
            fatalError("Could not retrieve documents directory")
        }
    }
    
    /// Delete the file from the Documents directory and reinitialize a brand new journal
    func deleteJournal() {
        let url = getDocumentsURL().appendingPathComponent("journal.json")
        do {
            // Delete the `.json` file
            try FileManager.default.removeItem(at: url)
            // Delete the images that are in the Documents directory
            ImageManager.sharedInstance.deleteImagesInDocumentsDirectory()
            // Reset the journals to empty
            journals = []
        } catch let err {
            print("Deleting file error: ", err)
        }
    }
    
    /// Save the journal to a JSON file
    func saveJournalToDisk() {
        // Create a URL for documents-directory/posts.json
        let url = getDocumentsURL().appendingPathComponent("journal.json")
        print("JSON location: \(url.absoluteString)")
        
        // Endcode our data to JSON Data
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(journals)
            // Write this data to the url
            try data.write(to: url, options: [])
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    
    func loadJournalFromDisk() -> [Journal] {
        let url = getDocumentsURL().appendingPathComponent("journal.json")
        print("Get: \(url)")
        if FileManager.default.fileExists(atPath: url.path) {
            print("File exists")
            let decoder = JSONDecoder()
            do {
                // Retrieve the data on the file in this path
                let data = try Data(contentsOf: url, options: [])
                // Decode an array of from this data
                let posts = try decoder.decode([Journal].self, from: data)
                return posts
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            // return a new array (first time run)
            return []
        }
    }
    
    
    
    /// Test if a journal entry has been sync'd to CloudKit
    /// - Parameters:
    ///   - uuid: <#uuid description#>
    ///   - recordName: <#recordName description#>
    ///   - changeTag: <#changeTag description#>
    func synced(uuid: UUID, recordName: String, changeTag: String) {
        // TODO: This does not work properly and/or may not be neceessary
        //        var updateJournals = journals
        //        for journal in updateJournals {
        //            if journal.uuid == uuid {
        //                journal.synced = true
        //                journal.cloudKitRecordId = recordName
        //                journal.cloudKitChangeTag = changeTag
        //            }
        //
        //        }
    }
    
}
