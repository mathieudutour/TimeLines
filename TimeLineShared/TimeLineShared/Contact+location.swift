//
//  Contact+location.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation
import CoreLocation

public extension Contact {
  var location: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: latitude,
      longitude: longitude
    )
  }

//  var timeZone: TimeZone {
//    let group = DispatchGroup()
//    group.enter()
//
//    var resolvedTimezone: TimeZone?
//
//    CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: self.location.latitude, longitude: self.location.longitude)) { placemarks, error in
//      print(placemarks)
//      if let placemarks = placemarks, placemarks.count > 0 {
//        resolvedTimezone = placemarks[0].timeZone
//      }
//      group.leave()
//    }
//
//    group.wait()
//
//    if let resolvedTimezone = resolvedTimezone {
//      return resolvedTimezone
//    }
//
//    return TimeZone(secondsFromGMT: 0)!
//  }
}
