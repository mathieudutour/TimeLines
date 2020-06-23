//
//  HostingController.swift
//  Time Lines WatchOS Extension
//
//  Created by Mathieu Dutour on 13/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import WatchKit
import WatchConnectivity
import SwiftUI
import TimeLineSharedWatchOS
import CoreData

struct WrapperView: View {
  var context: NSManagedObjectContext

  var body: some View {
    ContentView().environment(\.managedObjectContext, context)
  }
}

class HostingController: WKHostingController<WrapperView> {
  let context = CoreDataManager.shared.viewContext
  private var session = WCSession.default

  override var body: WrapperView {
    return WrapperView(context: context)
  }

  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    super.willActivate()

    // 2: Initialization of session and set as delegate this InterfaceController if it's supported
    if WCSession.isSupported() {
      session.delegate = self
      session.activate()
    }
  }

  func sendMessage() {
    /**
     *  The iOS device is within range, so communication can occur and the WatchKit extension is running in the
     *  foreground, or is running with a high priority in the background (for example, during a workout session
     *  or when a complication is loading its initial timeline data).
     */
    guard session.isReachable else {
      print("iPhone is not reachable!!")
      return
    }
    
    session.sendMessage(["request" : "contacts"], replyHandler: { (response) in
      if let tags = response["tags"] as? [[String: Any]] {
        tags.forEach { tag in
          guard
            let name = tag["name"] as? String,
            name != NO_VALUE,
            let red = tag["red"] as? Double,
            let green = tag["green"] as? Double,
            let blue = tag["blue"] as? Double
          else {
            return
          }
          if let existingTag = CoreDataManager.shared.findTag(name) {
            existingTag.red = red
            existingTag.green = green
            existingTag.blue = blue
          } else {
            let color = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
            CoreDataManager.shared.createTag(
              name: name,
              color: color
            )
          }
        }
      }
      if let contacts = response["contacts"] as? [[String: Any]] {
        contacts.forEach { contact in
          guard
            let name = contact["name"] as? String,
            name != NO_VALUE,
            let latitude = contact["latitude"] as? Double,
            let longitude = contact["longitude"] as? Double,
            let timezone = contact["timezone"] as? Int32,
            let locationName = contact["locationName"] as? String,
            let startTime = contact["startTime"],
            let endTime = contact["endTime"],
            let favorite = contact["favorite"] as? Bool,
            let index = contact["index"] as? Int16,
            let tags = contact["tags"] as? [String]
          else {
            return
          }
          let fetchedTags = CoreDataManager.shared.findTags(tags)
          let resolvedStartTime = (startTime as? String == NO_VALUE || startTime as? Double == nil) ? nil : Date(timeIntervalSince1970: startTime as! Double)
          let resolvedEndTime = (endTime as? String == NO_VALUE || endTime as? Double == nil) ? nil : Date(timeIntervalSince1970: endTime as! Double)

          if let existingContact = CoreDataManager.shared.findContact(withName: name) {
            existingContact.latitude = latitude
            existingContact.longitude = longitude
            if locationName != NO_VALUE {
              existingContact.locationName = locationName
            }
            existingContact.timezone = timezone
            existingContact.startTime = resolvedStartTime
            existingContact.endTime = resolvedEndTime
            existingContact.tags = NSSet(array: fetchedTags)
            existingContact.favorite = favorite
            existingContact.index = index
          } else {
            let existingContact = CoreDataManager.shared.createContact(
              name: name,
              latitude: latitude,
              longitude: longitude,
              locationName: locationName != NO_VALUE ? locationName : "",
              timezone: timezone,
              startTime: resolvedStartTime,
              endTime: resolvedEndTime,
              tags: NSSet(array: fetchedTags),
              favorite: favorite
            )
            existingContact?.index = index
          }
        }
      }
      CoreDataManager.shared.saveContext()
    }, errorHandler: { (error) in
      print("Error sending message: %@", error)
    })
  }
}

extension HostingController: WCSessionDelegate {

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    sendMessage()
  }

}
