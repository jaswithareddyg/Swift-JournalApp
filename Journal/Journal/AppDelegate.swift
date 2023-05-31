//
//  AppDelegate.swift
//  Journal
//
//  Created by Jaswitha Reddy G on 5/2/23.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        // Request authorization for notifications (this will present the standard user permission dialogue)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          if let error = error {
            print("Error: \(error.localizedDescription)")
          } else {
            // CloudKit operates on a background thread
            DispatchQueue.main.async {
                // Register this device with APNS to recieve notifications
                // (only after the user has granted permission)
              application.registerForRemoteNotifications()
            }
          }
        }

        // Local Notification for daily reminder
        setupLocalNotification()

        // Register a subscription for this device to let us know about any
        // changes to a `Journal` record
        CloudKitManager.sharedInstance.registerSubscription()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered Token: \(deviceToken.description)")
    }
    
    
    /// Called for push notifications coming from an APNS server.
    /// In this case, we are getting the changed record from cloudkit and then creating
    /// a new notification
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      
      // Get the APS notification data from the payload
      print("☁️ Debugging: \(userInfo)")
      let aps = userInfo["aps"] as! [String: AnyObject]
      print(aps)
      // Do Something with the content available data (if its there)
      let contentAvailable = aps["content-available"] as! Int
      
      if contentAvailable == 1 {
        let cloudKitInfo = userInfo["ck"] as! [String: AnyObject]
        let recordId = cloudKitInfo["qry"]?["rid"] as! String
        let field = cloudKitInfo["qry"]?["af"] as! [String: AnyObject]
        
        completionHandler(.newData)
      } else {
        
        completionHandler(.noData)
      }
    }
    
    /// Allow notifications to show if the app is front and center
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Setup a local notification to remind the user to write in their journal
    func setupLocalNotification() {
        // Setup Local Notification
        // https://developer.apple.com/documentation/usernotifications/scheduling_a_notification_locally_from_your_app
        let content = UNMutableNotificationContent()
        content.title = "📝"
        content.body = "Don't forget to write in your journal."
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "anything you want"]
        
        // Send daily at 8:30 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.hour = 30
           
        // Create the trigger as a repeating event
        // To make it easier to test, just choose a simple time interval of 5 seconds;
        // The notification will only show if the Journal app is NOT active
        //let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents,
        //                                            repeats: true)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: trigger)

        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
           if error != nil {
              // Handle any errors.
           }
        }
    }
    
    /// List all the notifcations registered  for this application (and optionally delete)
    /// User for debugging
    /// - Parameter andDelete: A `Bool` to delete all the notifications
    func listAllNotifications(andDelete: Bool) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notifications) in
            for notification in notifications {
                print(notification)
                if andDelete {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.identifier])
                }
            }
            
        }
    }
}
