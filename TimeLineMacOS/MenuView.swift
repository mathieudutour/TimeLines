//
//  MenuView.swift
//  TimeLine macOS
//
//  Created by Mathieu Dutour on 04/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import AppKit
import TimeLineSharedMacOS
import CoreLocation

struct MenuView: View {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  var body: some View {
    List {
      ForEach(contacts, id: \.self) { (contact: Contact) in
        VStack {
          ContactRow(
            name: contact.name ?? "",
            timezone: contact.timeZone,
            coordinate: contact.location
          )
          if self.contacts.last != contact {
            Divider()
          }
        }.onAppear(perform: {
          contact.refreshTimeZone()
        })
      }
    }
    .listStyle(SidebarListStyle())
  }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
