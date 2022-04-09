//
//  WatchHandler.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 11/05/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation
import WatchConnectivity
import TimeLineShared

class WatchHandler : NSObject, WCSessionDelegate {

  static let shared = WatchHandler()

  private var session = WCSession.default

  override init() {
    super.init()

    if WCSession.isSupported() {
      session.delegate = self
      session.activate()
    }

    print("isPaired?: \(session.isPaired), isWatchAppInstalled?: \(session.isWatchAppInstalled)")
  }

  // MARK: - WCSessionDelegate

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    /**
     * This is to re-activate the session on the phone when the user has switched from one
     * paired watch to second paired one. Calling it like this assumes that you have no other
     * threads/part of your code that needs to be given time before the switch occurs.
     */
    self.session.activate()
  }

  /// Observer to receive messages from watch and we be able to response it
  ///
  /// - Parameters:
  ///   - session: session
  ///   - message: message received
  ///   - replyHandler: response handler
  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    if message["request"] as? String != "contacts" {
      return replyHandler([:])
    }

    let contacts = CoreDataManager.shared.fetch()
    let tags = CoreDataManager.shared.fetchTags()

    let serializedContacts = contacts.map({ contact in
      [
        "latitude": contact.latitude,
        "longitude": contact.longitude,
        "timezone": contact.timezone,
        "name": contact.name ?? NO_VALUE,
        "locationName": contact.locationName ?? NO_VALUE,
        "startTime": contact.startTime?.timeIntervalSince1970 ?? NO_VALUE,
        "endTime": contact.endTime?.timeIntervalSince1970 ?? NO_VALUE,
        "favorite": contact.favorite,
        "index": contact.index,
        "tags": ((contact.tags?.allObjects ?? []) as! [Tag]).map { $0.name ?? NO_VALUE }
      ]
    })
    let serializedTags = tags.map({ tag in
      [
        "name": tag.name ?? NO_VALUE,
        "red": tag.red,
        "green": tag.green,
        "blue": tag.blue,
      ]
    })

    replyHandler([
      "contacts" : serializedContacts,
      "tags" : serializedTags
    ])
  }

}
