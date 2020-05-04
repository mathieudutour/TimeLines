//
//  Contact+location.swift
//  Time Lines Shared
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

  var timeZone: TimeZone? {
    TimeZone(secondsFromGMT: Int(self.timezone))
  }

  func refreshTimeZone() {
    CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, error in
      if
        let placemarks = placemarks,
        placemarks.count > 0,
        let timezone = placemarks[0].timeZone,
        timezone.secondsFromGMT() != Int(self.timezone)
      {
        self.timezone = Int32(timezone.secondsFromGMT())
      }
    }
  }
}
