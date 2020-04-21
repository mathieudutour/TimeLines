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

  public init(name: String, timezone: TimeZone?, coordinate: CLLocationCoordinate2D?) {
    self.name = name
    self.timezone = timezone
    self.coordinate = coordinate
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

      Line(coordinate: coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), timezone: timezone ?? TimeZone(secondsFromGMT: 0)!)
        .frame(width: 220, height: 80, alignment: .trailing)
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

