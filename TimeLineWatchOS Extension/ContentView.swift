//
//  ContentView.swift
//  Time Lines WatchOS Extension
//
//  Created by Mathieu Dutour on 13/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineSharedWatchOS

struct ContentView: View {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
    entity: Contact.entity(),
    sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  var body: some View {
    List {
      ForEach(contacts, id: \.self) { (contact: Contact) in
        ContactRow(
          name: contact.name ?? "",
          timezone: contact.timeZone,
          coordinate: contact.location,
          startTime: contact.startTime,
          endTime: contact.endTime
        )
        .onAppear(perform: {
          contact.refreshTimeZone()
        })
      }
      Group {
        Text("To add a new contact or edit existing ones, use the iOS or macOS app.").padding()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
