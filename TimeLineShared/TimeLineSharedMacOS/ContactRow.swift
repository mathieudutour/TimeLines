//
//  ContactRow.swift
//  Time Lines SharedMacOS
//
//  Created by Mathieu Dutour on 04/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import CoreLocation

public struct ContactRow: View {
  public var name: String
  public var timezone: TimeZone?
  public var coordinate: CLLocationCoordinate2D?
  public var startTime: Date?
  public var endTime: Date?

  public init(name: String, timezone: TimeZone?, coordinate: CLLocationCoordinate2D?, startTime: Date? = nil, endTime: Date? = nil) {
    self.name = name
    self.timezone = timezone
    self.coordinate = coordinate
    self.startTime = startTime
    self.endTime = endTime
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(timezone?.prettyPrintTimeDiff() ?? "")
          .font(.caption)
          .foregroundColor(Color(NSColor.secondaryLabelColor))
        Text(name)
          .font(.system(size: 28))
          .lineLimit(1)
      }

      Spacer()

      Line(coordinate: coordinate, timezone: timezone, startTime: startTime, endTime: endTime)
      .frame(width: 220, height: 80, alignment: .trailing)
      .offset(y: 30)
    }
  }
}

public struct ContactRow_Previews: PreviewProvider {
  public static var previews: some View {
    Group {
      ContactRow(name: "Mathieu", timezone: TimeZone(secondsFromGMT: 0), coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
      ContactRow(name: "Paul", timezone: TimeZone(secondsFromGMT: -3600), coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
      ContactRow(name: "Paul", timezone: TimeZone(secondsFromGMT: +7800), coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    }
    .previewLayout(.fixed(width: 300, height: 90))
  }
}

