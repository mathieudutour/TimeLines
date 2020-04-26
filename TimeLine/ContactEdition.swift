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
  private var contact: Contact?

  @State private var contactName: String
  @State private var locationText = ""
  @State private var location: CLLocationCoordinate2D?
  @State private var showModal = false
  @State private var saving = false
  @State private var customStartTime = false
  @State private var customEndTime = false
  @State private var startTime: Date
  @State private var endTime: Date
  @State private var search = ""
  @State private var tags: [Tag]
  @State private var favorite = true

  @State private var timezone: TimeZone?

  @State private var locationCompletion: MKLocalSearchCompletion?

  init() {
    self.contact = RouteState.shared.editingContact

    let today = Calendar.current.startOfDay(for: Date())

    _contactName = State(initialValue: contact?.name ?? "")
    _locationText = State(initialValue: contact?.locationName ?? "")
    _location = State(initialValue: contact?.location)
    _timezone = State(initialValue: contact?.timeZone)
    _customStartTime = State(initialValue: contact?.startTime != nil)
    _customEndTime = State(initialValue: contact?.endTime != nil)
    _startTime = State(initialValue: contact?.startTime?.inTodaysTime().addingTimeInterval(-TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) ?? today.addingTimeInterval(3600 * 9))
    _endTime = State(initialValue: contact?.endTime?.inTodaysTime().addingTimeInterval(-TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) ?? today.addingTimeInterval(3600 * 18))
    _tags = State(initialValue: contact?.tags?.map({ $0 as! Tag }) ?? [])
    _favorite = State(initialValue: contact?.favorite ?? true)
  }

  var body: some View {
    NavigationView {
      List {
        Section(footer: MapView(coordinate: location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), span: location == nil ? 45 : 0.02).frame(height: 150).padding(.init(top: -6, leading: -16, bottom: 0, trailing: -16))) {
          HStack {
            Text("Name")
            TextField("Jane Doe", text: $contactName)
              .multilineTextAlignment(.trailing)
              .frame(alignment: .trailing)
          }

          HStack {
            Text("Location")
            Spacer()
            Button(action: {
              UIApplication.shared.endEditing(true)
              self.showModal = true
            }) {
              Text(locationText == "" ? "San Francisco" : locationText)
                .foregroundColor(Color(locationText == "" ? UIColor.placeholderText : UIColor.label))
                .frame(alignment: .trailing)
            }.sheet(isPresented: self.$showModal) {
              LocationSearchController(searchBarPlaceholder: "Search for a place") { mapItem in
                Button(action: {
                  self.locationCompletion = mapItem
                  self.locationText = mapItem.title
                  self.updateLocation(mapItem)
                  self.showModal = false
                }) {
                  Text(mapItem.title)
                }
              }
            }
          }
        }

        Section(footer: Text("Your favorite contacts will show up in the Today Widget.")) {
          Toggle(isOn: $favorite) {
            Text("Favorite")
          }
        }

        Section(footer: Text("You can add different tags to a contact to easily search for it in the list.")) {
          HStack {
            Text("Tags")
            SearchBar(placeholder: "Add tags...", search: $search, tokens: $tags, allowCreatingTokens: true)
          }
        }

        Section(footer: Text("A time line will show the sunrise and sunset times at the location of the contact by default. You can customize those times if you'd like to show working hours for example.")) {
          CustomTimePicker(text: "Customize rise time", custom: $customStartTime, time: $startTime)
          CustomTimePicker(text: "Customize set time", custom: $customEndTime, time: $endTime)
        }
      }
      .listStyle(GroupedListStyle())
      .resignKeyboardOnDragGesture()
      .navigationBarTitle(Text(contact == nil ? "New Contact" : "Edit Contact"))
      .navigationBarItems(leading: Button(action: back) {
          Text("Cancel")
        }, trailing: Button(action: {
          if !self.saving {
            self.save()
          }
        }) {
          if self.saving {
            ActivityIndicator(isAnimating: true)
          } else {
            Text("Done")
          }
        }
        .disabled(!didUpdateUser() || !valid())
      )
    }.navigationViewStyle(StackNavigationViewStyle())
  }

  func back() {
    if let contact = contact {
      RouteState.shared.navigate(.contact(contact: contact))
    } else {
      RouteState.shared.navigate(.list)
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

  func didChangeTags() -> Bool {
    if let previousTags = contact?.arrayTags {
      return tags != previousTags
    } else {
      return tags.count > 0
    }
  }

  func didChangeFavorite() -> Bool {
    if let previous = contact?.favorite {
      return previous != favorite
    }
    return false
  }

  func didUpdateUser() -> Bool {
    return didChangeLocation() || didChangeName() || didChangeTime(contact?.startTime, customStartTime, startTime) || didChangeTime(contact?.endTime, customEndTime, endTime) || didChangeTags() || didChangeFavorite()
  }

  func valid() -> Bool {
    return (locationCompletion != nil || contact?.locationName != nil) && contactName.count > 0
  }

  func updateLocation(_ locationCompletion: MKLocalSearchCompletion) {
    let request = MKLocalSearch.Request(completion: locationCompletion)
    request.resultTypes = .address
    let search = MKLocalSearch(request: request)
    search.start { response, _ in
      guard let response = response, let mapItem = response.mapItems.first else {
        return
      }
      self.location = mapItem.placemark.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
  }

  func save() {
    if let locationCompletion = locationCompletion, didChangeLocation() {
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
        self.back()
      }
    } else if didUpdateUser() {
      saving = true
      self.updateContact()
      back()
    }
  }

  func updateContact() {
    if let contact = contact {
      contact.name = contactName
      contact.latitude = location?.latitude ?? 0
      contact.longitude = location?.longitude ?? 0
      contact.locationName = locationText
      contact.timezone = Int16(timezone?.secondsFromGMT() ?? 0)
      contact.startTime = customStartTime ? startTime.addingTimeInterval(TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) : nil
      contact.endTime = customEndTime ? endTime.addingTimeInterval(TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT())) : nil
      contact.tags = NSSet(array: tags)
      contact.favorite = favorite
      CoreDataManager.shared.saveContext()
    } else {
      CoreDataManager.shared.createContact(
        name: contactName,
        latitude: location?.latitude ?? 0,
        longitude: location?.longitude ?? 0,
        locationName: locationText,
        timezone: Int16(timezone?.secondsFromGMT() ?? 0),
        startTime: customStartTime ? startTime : nil,
        endTime: customEndTime ? endTime : nil,
        tags: NSSet(array: tags),
        favorite: favorite
      )
    }
    saving = false
  }
}

struct ContactEdition_Previews: PreviewProvider {
  static var previews: some View {
    return ContactEdition()
  }
}
