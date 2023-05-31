//
//  Journal.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//


import Foundation
import UIKit

/// Describes a journal entry
public struct Journal: Codable {
    
    // Entry metadata
    let uuid: UUID
    var synced: Bool
    var note: String?
    var imageName: String?
    var createdDate: Date
    
    // CloudKit metadata that will be available once a record is successfully stored on CloudKit
    var cloudKitRecordId: String?
    var cloudKitChangeTag: String?

    // Data extracted from image
    var date: Date
    var latitude: Double?
    var longitude: Double?
    var tags: [String]?
}

