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

  @State private var locationCompletion: MKLocalSearchCompletion?

  init(contact: Contact?) {
    self.contact = contact
    _contactName = State(initialValue: contact?.name ?? "")
    _locationText = State(initialValue: contact?.locationName ?? "")
    _location = State(initialValue: contact?.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
    _timezone = State(initialValue: contact?.timeZone)
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
            SearchController(searchBarPlaceholder: "Search for a place") { mapItem in
              Button(action: {
                self.locationCompletion = mapItem
                self.locationText = mapItem.title
                self.showModal = false
              }) {
                Text(mapItem.title)
              }
            }
          }
        }
      }
      .padding()

      Spacer()
    }.navigationBarItems(trailing: Button(action: {
      self.save()
    }) {
      Text("Save")
    }
    .disabled(contactName == "" || locationText == ""))
  }

  func save() {
    self.presentationMode.wrappedValue.dismiss()
    if let locationCompletion = locationCompletion, locationCompletion.title != contact?.locationName {
      // need to fetch the new location
      let request = MKLocalSearch.Request(completion: locationCompletion)
      request.resultTypes = .address
      let search = MKLocalSearch(request: request)
      search.start { response, _ in
        guard let response = response, let mapItem = response.mapItems.first else {
          return
        }
        self.timezone = mapItem.timeZone
        self.location = mapItem.placemark.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.updateContact()
      }
    } else if contactName != contact?.name {
      self.updateContact()
    }
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
  }
}

struct ContactEdition_Previews: PreviewProvider {
  static var previews: some View {
    return ContactEdition(contact: nil)
  }
}
