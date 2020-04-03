//
//  ContactEdition.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared
import MapKit
import CoreLocation

struct ContactEdition: View {
  @Environment(\.presentationMode) var presentationMode

  var contact: Contact?

  @State private var contactName: String
  @State private var locationText = ""
  @State private var location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
  @State private var showModal = false

  @State private var timezone: TimeZone?

  init(contact: Contact?) {
    _contactName = State(initialValue: contact?.name ?? "")
    _locationText = State(initialValue: contact?.locationName ?? "")
    _timezone = State(initialValue: TimeZone(secondsFromGMT: Int(contact?.timezone ?? 0)))
  }

  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        HStack {
          Text("Name")
            .font(.title)
          TextField("Jane Doe", text: $contactName)
            .font(.title)
            .multilineTextAlignment(.trailing)
            .frame(alignment: .trailing)
        }

        HStack {
          Text("Location")
            .font(.title)
          Spacer()
          Button(action: {
              self.showModal = true
          }) {
            Text(locationText == "" ? "San Francisco" : locationText)
              .font(.title)
              .foregroundColor(Color(locationText == "" ? UIColor.placeholderText : UIColor.label))
              .frame(alignment: .trailing)
          }.sheet(isPresented: self.$showModal) {
            SearchController("Search for a place", searchedText: self.$locationText, isFirstResponder: true) { mapItem in
              Button(action: {
                self.timezone = mapItem.timeZone
                self.locationText = mapItem.name ?? ""
                self.location = mapItem.placemark.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                self.showModal = false
              }) {
                Text(mapItem.name ?? "")
              }
            }
          }
        }
      }
      .padding()

      Spacer()
    }.navigationBarItems(trailing: Button(action: {
      self.updateContact()
    }) {
      Text("Save")
    }
    .disabled(contactName == "" || locationText == ""))
  }

  func updateContact() {
    if let contact = contact {
      contact.name = contactName
      contact.latitude = location.latitude
      contact.longitude = location.longitude
      contact.locationName = locationText
      contact.timezone = Int16(timezone?.secondsFromGMT() ?? 0)
      CoreDataManager.shared.saveContext()
    } else {
      CoreDataManager.shared.createContact(
        name: contactName,
        latitude: location.latitude,
        longitude: location.longitude,
        locationName: locationText,
        timezone: Int16(timezone?.secondsFromGMT() ?? 0)
      )
    }

    self.presentationMode.wrappedValue.dismiss()
  }
}

struct ContactEdition_Previews: PreviewProvider {
  static var previews: some View {
    return ContactEdition(contact: nil)
  }
}
