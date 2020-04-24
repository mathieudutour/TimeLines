//
//  ContactDetails.swift
//  Time Lines Shared
//
//  Created by Mathieu Dutour on 07/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI

public struct TagView: View {
  @Environment(\.presentationMode) var presentationMode

  @ObservedObject var tag: Tag
  public var onSelectTag: (_ tag: Tag, _ presentationMode: inout PresentationMode) -> Void

  public init(tag: Tag, onSelectTag: @escaping (_ tag: Tag, _ presentationMode: inout PresentationMode) -> Void = { _, _ in }) {
    self.tag = tag
    self.onSelectTag = onSelectTag
  }

  public var body: some View {
    Button(action: {
      self.onSelectTag(self.tag, &self.presentationMode.wrappedValue)
    }) {
      HStack {
        tag.swiftCircle
          .frame(width: 15, height: 15)
          .padding(.leading, 4)
        Text(tag.name ?? "").font(.subheadline).foregroundColor(Color.white)
          .padding(.init(top: 2, leading: 0, bottom: 2, trailing: 4))
      }.background(Color.gray)
      .cornerRadius(3)
    }
  }
}

struct Main: View {
  @ObservedObject var contact: Contact
  @ObservedObject var currentTime = CurrentTime.shared

  var onSelectTag: (_ tag: Tag, _ presentationMode: inout PresentationMode) -> Void

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .top) {
        Text(contact.name ?? "No Name")
          .font(.title)
        Spacer()
        Text(contact.timeZone?.prettyPrintTimeDiff() ?? "")
          .font(.title)
      }

      HStack(alignment: .top) {
        Text(contact.locationName ?? "No location")
          .font(.subheadline)
        Spacer()
        Text(contact.timeZone?.prettyPrintTime(currentTime.now) ?? "")
          .font(.subheadline)
      }
      ScrollView(.horizontal) {
        HStack(spacing: 10) {
          ForEach(contact.arrayTags, id: \Tag.name) { tag in
            TagView(tag: tag, onSelectTag: self.onSelectTag)
          }
        }
      }
      Line(coordinate: contact.location, timezone: contact.timeZone, startTime: contact.startTime, endTime: contact.endTime)
        .frame(height: 80)
        .padding()
    }
    .padding()
  }
}

public struct ContactDetails<EditView>: View where EditView: View {
  @ObservedObject var contact: Contact
  var editView: () -> EditView
  var onSelectTag: (_ tag: Tag, _ presentationMode: inout PresentationMode) -> Void

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }

  public init(contact: Contact, onSelectTag: @escaping (_ tag: Tag, _ presentationMode: inout PresentationMode) -> Void = { _, _ in }, @ViewBuilder editView: @escaping () -> EditView) {
    self.contact = contact
    self.editView = editView
    self.onSelectTag = onSelectTag
  }

  #if os(iOS) || os(tvOS) || os(watchOS)
  public var body: some View {
    VStack {
      MapView(coordinate: contact.location)
      .edgesIgnoringSafeArea(.top)
      .frame(height: 300)

      Main(contact: contact, onSelectTag: onSelectTag)

      Spacer()
    }
    .navigationBarItems(trailing: editView())
  }
  #elseif os(macOS)
  public var body: some View {
    VStack {
      ZStack(alignment: .topTrailing) {
        MapView(coordinate: contact.location).edgesIgnoringSafeArea(.top)
        editView().padding()
      }
      .frame(height: 300)

      Main(contact: contact, onSelectTag: onSelectTag)

      Spacer()
    }
  }
  #endif
}

struct ContactDetails_Previews: PreviewProvider {
  static var previews: some View {
    let dummyContact = Contact()
    dummyContact.name = "Mathieu"
    dummyContact.latitude = 34.011286
    dummyContact.longitude = -116.166868
    return ContactDetails(contact: dummyContact) {
      Button(action: {
        print("edit")
      }) {
        Text("Edit")
      }
    }
  }
}

