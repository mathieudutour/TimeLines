//
//  ContactDetail.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared

struct ContactDetail: View {
  var contact: Contact

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }

  var body: some View {
    VStack {
      MapView(coordinate: contact.location)
        .edgesIgnoringSafeArea(.top)
        .frame(height: 300)

      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          Text(contact.name ?? "No Name")
            .font(.title)
          Spacer()
          Text(dateFormatter.string(from: Date().addingTimeInterval(TimeInterval(TimeZone(secondsFromGMT: Int(contact.timezone))?.diffInSecond() ?? 0))))
            .font(.title)
        }

        HStack(alignment: .top) {
          Text(contact.locationName ?? "No location")
            .font(.subheadline)
          Spacer()
          Text(TimeZone(secondsFromGMT: Int(contact.timezone))?.prettyPrint() ?? "")
            .font(.subheadline)
        }
      }
      .padding()

      Spacer()
    }
  }
}

struct ContactDetail_Previews: PreviewProvider {
  static var previews: some View {
    let dummyContact = Contact()
    dummyContact.name = "Mathieu"
    dummyContact.latitude = 34.011286
    dummyContact.longitude = -116.166868
    return ContactDetail(contact: dummyContact)
  }
}
