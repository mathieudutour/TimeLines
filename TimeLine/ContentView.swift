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

struct AddNewContact: View {
  var body: some View {
    NavigationLink(destination: ContactEdition(contact: nil)) {
      HStack {
        Image(systemName: "plus").padding()
        Text("Add a new contact")
      }
    }
  }
}

struct ContentView: View {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  @State private var showingSheet = false

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
        .onMove(perform: self.moveContact)

        AddNewContact().foregroundColor(Color(UIColor.secondaryLabel))
      }
      .navigationBarTitle(Text("Contacts"))
      .navigationBarItems(leading: EditButton(), trailing: Button(action: {
        self.showingSheet = true
      }) {
        Image(systemName: "person")
      }
      .actionSheet(isPresented: $showingSheet) {
        ActionSheet(title: Text("Settings"), buttons: [
          .default(Text("Send Feedback"), action: {
            UIApplication.shared.open(App.feedbackPage)
          }),
          .default(Text("Restore Purchases"), action: {
            print("restore purchase")
          }),
          .cancel()
        ])
      })
      if contacts.count > 0 {
        ContactDetail(contact: contacts[0])
      } else {
        VStack {
          Text("Get started by adding a new contact")
          AddNewContact().padding(.trailing, 20).foregroundColor(Color.accentColor).border(Color.accentColor)
        }
      }
    }

  }

  private func deleteContact(at indexSet: IndexSet) {
    for index in indexSet {
      CoreDataManager.shared.deleteContact(contacts[index])
    }
  }

  private func moveContact(from source: IndexSet, to destination: Int) {
    for index in source {
      CoreDataManager.shared.moveContact(from: index, to: destination)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
