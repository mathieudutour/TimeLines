//
//  ManageContacts.swift
//  Time LinesMacOS
//
//  Created by Mathieu Dutour on 07/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineSharedMacOS
import CoreLocation

struct ManageContacts: View {
  @Environment(\.managedObjectContext) var context

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  @State var selectedContact: Contact?

  @State private var showingEdit = false
  @State private var showingSheet = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationView {
      List(selection: $selectedContact) {
        Button(action: {
          self.selectedContact = nil
          self.showingEdit = true
        }) {
          HStack {
            Image(nsImage: NSImage(named: NSImage.addTemplateName)!)
            Text("Add a new contact")
          }
        }

        ForEach(contacts, id: \.self) { (contact: Contact) in
          VStack {
            HStack {
              Text(contact.name ?? "")
                .font(.system(size: 20))
                .lineLimit(1)
              Spacer()
              Text(contact.timeZone?.prettyPrintTimeDiff() ?? "").padding()
            }
            Divider()
          }
          .tag(contact)
          .onAppear(perform: {
            contact.refreshTimeZone()
          })
          .contextMenu(menuItems: {
            Button(action: {
              self.selectedContact = contact
              self.showingEdit = true
            }) {
              Text("Edit Contact")
            }
            Button(action: {
              self.selectedContact = nil
              self.showingEdit = false
              CoreDataManager.shared.deleteContact(contact)
            }) {
              Text("Delete Contact")
            }
          })
        }
        .onDelete(perform: self.deleteContact)
        .onMove(perform: self.moveContact)
      }
      .padding(.top)
      .frame(minWidth: 200)
      .listStyle(SidebarListStyle())

      if showingEdit {
        ContactEdition(contact: $selectedContact, showingEdit: $showingEdit)
      } else if selectedContact != nil {
        ContactDetails(contact: selectedContact!) {
          Button(action: {
            self.showingEdit = true
          }) {
            Text("Edit")
          }
        }
      }
    }
    .edgesIgnoringSafeArea(.top)
    .navigationViewStyle(DoubleColumnNavigationViewStyle())
    .background(Blur().edgesIgnoringSafeArea(.top))
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

struct ManageContacts_Previews: PreviewProvider {
  static var previews: some View {
    ManageContacts()
  }
}

