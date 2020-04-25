//
//  WidgetView.swift
//  Time Lines Widget
//
//  Created by Mathieu Dutour on 03/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared
import CoreLocation

struct WidgetView : View {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  var extensionContext: NSExtensionContext?

  var body: some View {
    List {
      ForEach(contacts, id: \.self) { (contact: Contact) in
        Button(action: {
          guard let url = URL(string: "timelines://contact/\(contact.name ?? "")") else {
            return
          }
          self.extensionContext?.open(url)
        }) {
          ContactRow(
            name: contact.name ?? "",
            timezone: contact.timeZone,
            coordinate: contact.location,
            startTime: contact.startTime,
            endTime: contact.endTime
          ).onAppear(perform: {
            contact.refreshTimeZone()
          })
        }
      }
    }
  }
}
