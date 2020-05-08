//
//  ContactEdition.swift
//  Time LinesMacOS
//
//  Created by Mathieu Dutour on 08/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineSharedMacOS
import MapKit
import CoreLocation

struct CustomTimePicker: View {
  var text: String
  @Binding var custom: Bool
  @Binding var time: Date

  var body: some View {
    HStack {
      Toggle(isOn: $custom) {
        Text(text)
      }
      Spacer()
      if custom {
        DatePicker(selection: $time, displayedComponents: .hourAndMinute) {
          Text("")
        }.labelsHidden()
      }
    }
  }
}

struct ButtonThatLookLikeTextFieldStyle: ButtonStyle {
  var locationText: String

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .font(.headline)
      .padding(10)
      .foregroundColor(Color(self.locationText == "" ? NSColor.placeholderTextColor : NSColor.labelColor))
      .background(Color(NSColor.controlBackgroundColor))
      .border(Color(NSColor.controlShadowColor), width: 0.5)
  }
}

struct ContactEdition: View {
  @Environment(\.presentationMode) var presentationMode

  @Binding var contact: Contact?
  @Binding var showingEdit: Bool
  @State private var saving = false

  @State private var contactName: String
  @State private var locationText = ""
  @State private var location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
  @State private var showModal = false

  @State private var timezone: TimeZone?
  @State private var customStartTime = false
  @State private var customEndTime = false
  @State private var startTime: Date
  @State private var endTime: Date
  @State private var favorite = true

  @State private var locationCompletion: MKLocalSearchCompletion?

  init(contact: Binding<Contact?>, showingEdit: Binding<Bool>) {
    let today = Calendar.current.startOfDay(for: Date())

    self._contact = contact
    self._showingEdit = showingEdit
    _contactName = State(initialValue: contact.wrappedValue?.name ?? "")
    _locationText = State(initialValue: contact.wrappedValue?.locationName ?? "")
    _location = State(initialValue: contact.wrappedValue?.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
    _timezone = State(initialValue: contact.wrappedValue?.timeZone)
    _customStartTime = State(initialValue: contact.wrappedValue?.startTime != nil)
    _customEndTime = State(initialValue: contact.wrappedValue?.endTime != nil)
    _startTime = State(initialValue: contact.wrappedValue?.startTime?.inTodaysTime().addingTimeInterval(-TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) ?? today.addingTimeInterval(3600 * 9))
    _endTime = State(initialValue: contact.wrappedValue?.endTime?.inTodaysTime().addingTimeInterval(-TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) ?? today.addingTimeInterval(3600 * 18))
    _favorite = State(initialValue: contact.wrappedValue?.favorite ?? true)
  }

  var body: some View {
    VStack {
      Spacer()
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

          GeometryReader { p in
            Button(action: {
              self.showModal = true
            }) {
              Text(self.locationText == "" ? "San Francisco" : self.locationText)
                .multilineTextAlignment(.trailing)
                .font(.title)
                .frame(width: p.size.width - 20, height: 22, alignment: .trailing)
                .foregroundColor(Color(self.locationText == "" ? NSColor.placeholderTextColor : NSColor.labelColor))
            }
            .frame(height: 22, alignment: .trailing)
            .buttonStyle(ButtonThatLookLikeTextFieldStyle(locationText: self.locationText))
            .sheet(isPresented: self.$showModal) {
              SearchController(resultView: { mapItem in
                Button(action: {
                  self.locationCompletion = mapItem
                  self.locationText = mapItem.title
                  self.showModal = false
                }) {
                  Text(mapItem.title)
                }
                .buttonStyle(ButtonThatLookLikeRowStyle())
              })
            }
          }.frame(height: 30)

        }

        Text("Your favorite contacts will show up in the main popover.")
          .padding(.top, 50)
          .foregroundColor(Color.secondary)
        HStack {
          Toggle(isOn: $favorite) {
            Text("Favorite")
          }
          Spacer()
        }

        Text("A time line will show the sunrise and sunset times at the location of the contact by default. You can customize those times if you'd like to show working hours for example.")
          .padding(.top, 50)
          .foregroundColor(Color.secondary)
        CustomTimePicker(text: "Customize rise time", custom: $customStartTime, time: $startTime)
        CustomTimePicker(text: "Customize set time", custom: $customEndTime, time: $endTime)

        HStack {
          Spacer()
          Button(action: {
            self.save()
          }) {
            Text("Done")
          }
          .padding(.top)
          .disabled(contactName == "" || locationText == "")
        }
        Spacer()
      }
      .padding()

      Spacer()
    }
  }

  func didChangeTime(_ previousTime: Date?, _ custom: Bool, _ newTime: Date) -> Bool {
    return (previousTime == nil && custom) || (previousTime != nil && !custom) || (previousTime != nil && previousTime?.inTodaysTime().addingTimeInterval(-TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) != newTime)
  }

  func didChangeLocation() -> Bool {
    return locationCompletion != nil && locationCompletion?.title != contact?.locationName
  }

  func didChangeName() -> Bool {
    return contactName.count > 0 && contactName != contact?.name
  }

//  func didChangeTags() -> Bool {
//    if let previousTags = contact?.arrayTags {
//      return tags != previousTags
//    } else {
//      return tags.count > 0
//    }
//  }

  func didChangeFavorite() -> Bool {
    if let previous = contact?.favorite {
      return previous != favorite
    }
    return false
  }

  func didUpdateUser() -> Bool {
    return didChangeLocation() || didChangeName() || didChangeTime(contact?.startTime, customStartTime, startTime) || didChangeTime(contact?.endTime, customEndTime, endTime) || didChangeFavorite() // || didChangeTags()
  }

  func valid() -> Bool {
    return (locationCompletion != nil || contact?.locationName != nil) && contactName.count > 0
  }

  func save() {
    if let locationCompletion = locationCompletion, didChangeLocation() {
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
    } else if didUpdateUser() {
      self.updateContact()
    } else {
      showingEdit = false
    }
  }

  func updateContact() {
    if let contact = contact {
      contact.name = contactName
      contact.latitude = location.latitude
      contact.longitude = location.longitude
      contact.locationName = locationText
      contact.timezone = Int32(timezone?.secondsFromGMT() ?? 0)
      contact.startTime = customStartTime ? startTime.addingTimeInterval(TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) : nil
      contact.endTime = customEndTime ? endTime.addingTimeInterval(TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) : nil
      contact.favorite = favorite
      CoreDataManager.shared.saveContext()
    } else {
      contact = CoreDataManager.shared.createContact(
        name: contactName,
        latitude: location.latitude,
        longitude: location.longitude,
        locationName: locationText,
        timezone: Int32(timezone?.secondsFromGMT() ?? 0),
        startTime: customStartTime ? startTime : nil,
        endTime: customEndTime ? endTime : nil,
        tags: NSSet(),
        favorite: favorite
      )
    }
    showingEdit = false
  }
}

struct ContactEdition_Previews: PreviewProvider {

  static var previews: some View {
    var contact: Contact? = nil
    var showingEdit = true
    return ContactEdition(contact: Binding(get: { contact }, set: { new in contact = new }), showingEdit: Binding(get: { showingEdit }, set: { new in showingEdit = new }))
  }
}

