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
//    CLGeocoder().reverseGeocodeLocation(self.location) { placemarks, error in
//      
//    }
//  }
}
