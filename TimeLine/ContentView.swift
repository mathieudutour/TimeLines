//
//  ContentView.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared
import CoreLocation

struct ContentView: View {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  var body: some View {
    NavigationView {
      List {
        ForEach(contacts, id: \.self) { (contact: Contact) in
          NavigationLink(destination: ContactDetail(contact: contact)) {
            ContactRow(
              name: contact.name ?? "",
              timezone: TimeZone(secondsFromGMT: Int(contact.timezone)),
              coordinate: contact.location
            )
          }
        }
        .onDelete(perform: self.deleteContact)
      }
      .navigationBarTitle(Text("Contacts"))
      .navigationBarItems(
        trailing: NavigationLink(destination: ContactEdition(contact: nil)) {
        Text("Add Contact")
      })
    }

  }

  private func deleteContact(at indexSet: IndexSet) {
    for index in indexSet {
      CoreDataManager.shared.deleteContact(contacts[index])
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
