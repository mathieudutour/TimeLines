//
//  ContactEdition.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared
import MapKit
import CoreLocation

struct CustomTimePicker: View {
  var text: String
  @Binding var custom: Bool
  @Binding var time: Date

  var body: some View {
    VStack {
      Toggle(isOn: $custom) {
        Text(text)
      }
      if custom {
        DatePicker(selection: $time, displayedComponents: .hourAndMinute) {
          Text("")
        }.labelsHidden()
      }
    }
  }
}

struct ContactEdition: View {
  @Environment(\.presentationMode) var presentationMode

  var contact: Contact?

  @State private var contactName: String
  @State private var locationText = ""
  @State private var location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
  @State private var showModal = false
  @State private var saving = false
  @State private var customStartTime = false
  @State private var customEndTime = false
  @State private var startTime: Date
  @State private var endTime: Date

  @State private var timezone: TimeZone?

  @State private var locationCompletion: MKLocalSearchCompletion?

  init(contact: Contact?) {
    self.contact = contact

    let today = Calendar.current.startOfDay(for: Date())

    _contactName = State(initialValue: contact?.name ?? "")
    _locationText = State(initialValue: contact?.locationName ?? "")
    _location = State(initialValue: contact?.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
    _timezone = State(initialValue: contact?.timeZone)
    _customStartTime = State(initialValue: contact?.startTime != nil)
    _customEndTime = State(initialValue: contact?.endTime != nil)
    _startTime = State(initialValue: contact?.startTime?.inTodaysTime() ?? today.addingTimeInterval(3600 * 9))
    _endTime = State(initialValue: contact?.endTime?.inTodaysTime() ?? today.addingTimeInterval(3600 * 18))
  }

  var body: some View {
    ScrollView {
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
        Text("A time line will show the sunrise and sunset times at the location of the contact by default. You can customize those times if you'd like to show working hours for example.")
          .padding(.top, 50)
          .foregroundColor(Color.secondary)
        CustomTimePicker(text: "Customize rise time", custom: $customStartTime, time: $startTime)
        CustomTimePicker(text: "Customize set time", custom: $customEndTime, time: $endTime)
      }
      .padding()

      Spacer()
    }.navigationBarItems(trailing: Button(action: {
      if !self.saving {
        self.save()
      }
    }) {
      if self.saving {
        ActivityIndicator(isAnimating: true)
      } else {
        Text("Save")
      }
    }
    .disabled(contactName == "" || locationText == ""))
  }

  func didChangeTime(_ previousTime: Date?, _ custom: Bool, _ newTime: Date) -> Bool {
    return (previousTime == nil && custom) || (previousTime != nil && !custom) || (previousTime != nil && previousTime?.inTodaysTime() != newTime)
  }

  func save() {
    if let locationCompletion = locationCompletion, locationCompletion.title != contact?.locationName {
      saving = true
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
        self.presentationMode.wrappedValue.dismiss()
      }
    } else if contactName != contact?.name || didChangeTime(contact?.startTime, customStartTime, startTime) || didChangeTime(contact?.endTime, customEndTime, endTime) {
      saving = true
      self.updateContact()
      self.presentationMode.wrappedValue.dismiss()
    }
  }

  func updateContact() {
    if let contact = contact {
      contact.name = contactName
      contact.latitude = location.latitude
      contact.longitude = location.longitude
      contact.locationName = locationText
      contact.timezone = Int16(timezone?.secondsFromGMT() ?? 0)
      contact.startTime = customStartTime ? startTime : nil
      contact.endTime = customEndTime ? endTime : nil
      CoreDataManager.shared.saveContext()
    } else {
      CoreDataManager.shared.createContact(
        name: contactName,
        latitude: location.latitude,
        longitude: location.longitude,
        locationName: locationText,
        timezone: Int16(timezone?.secondsFromGMT() ?? 0),
        startTime: customStartTime ? startTime : nil,
        endTime: customEndTime ? endTime : nil
      )
    }
    saving = false
  }
}

struct ContactEdition_Previews: PreviewProvider {
  static var previews: some View {
    return ContactEdition(contact: nil)
  }
}
