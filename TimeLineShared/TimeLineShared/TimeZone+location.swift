//
//  TimeZone+location.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 23/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation
import CoreLocation

fileprivate var identifiersToLocation: [String: [Double]]?

public extension TimeZone {
  private static func importTimeZoneData() -> [String: [Double]] {
    if let existingData = identifiersToLocation {
      return existingData
    }
    
    let currentBundle = Bundle(for: CoreDataManager.self)

    let filePath = currentBundle.url(forResource: "timezone-data", withExtension: ".json")
    do {
      if
        let filePath = filePath,
        let jsonData = try? Data(contentsOf: filePath),
        let timeZones = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: [Double]]
      {
        return timeZones
      }
    } catch let error as NSError {
      NSLog("Invalid timezoneDB format %@", error.localizedDescription)
    }

    return [String: [Double]]()
  }

  var roughLocation: CLLocationCoordinate2D? {
    guard let matchedLocation = TimeZone.importTimeZoneData().first(where: { $0.key == self.identifier }) else {
      return nil
    }
    return CLLocationCoordinate2D(latitude: matchedLocation.value[0], longitude: matchedLocation.value[1])
  }
}
