//
//  ContentView.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared
import CoreLocation

struct MeRow: View {
  @Environment(\.editMode) var editMode

  var contacts: FetchedResults<Contact>

  private let currentTimeZone = TimeZone.autoupdatingCurrent
  private let roughLocation = TimeZone.autoupdatingCurrent.roughLocation

  var body: some View {
    Group {
      if editMode?.wrappedValue == EditMode.inactive || contacts.count == 0 {
        ContactRow(
          name: "Me",
          timezone: currentTimeZone,
          coordinate: roughLocation
        ).padding(.trailing, 15)
      }
    }
  }
}

struct BindedContactRow: View {
  @Environment(\.editMode) var editMode
  @EnvironmentObject var routeState: RouteState

  var contact: Contact
  @Binding var search: String
  @Binding var searchTokens: [Tag]

  var destination: some View {
    ContactDetails(contact: contact, onSelectTag: { tag, presentationMode in
      self.routeState.navigate(.list)
      presentationMode.dismiss()
      self.searchTokens = [tag]
      self.search = ""
    }, editView: {
      Button(action: {
        self.routeState.navigate(.editContact(contact: self.contact))
      }) {
        Text("Edit")
      }
      .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
      .background(Color(UIColor.systemBackground))
      .cornerRadius(5)
    })
  }

  var body: some View {
    NavigationLink(destination: destination, tag: contact, selection: $routeState.contactDetailed) {
      ContactRow(
        name: contact.name ?? "",
        timezone: contact.timeZone,
        coordinate: contact.location,
        startTime: contact.startTime,
        endTime: contact.endTime,
        hideLine: editMode?.wrappedValue == .active
      )
    }.onAppear(perform: {
      self.contact.refreshTimeZone()
    })
  }
}

struct ContentView: View, ContactPickerDelegate {
  @Environment(\.managedObjectContext) var context
  @EnvironmentObject var routeState: RouteState

  @FetchRequest(
      entity: Contact.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)]
  ) var contacts: FetchedResults<Contact>

  @State private var showingSheet = false
  @State private var showingNewContactOptions = false
  @State private var errorMessage: String?
  @State private var search = ""
  @State private var searchTokens: [Tag] = []

  var addNewContact: some View {
    Button(action: {
      showingNewContactOptions = true
    }) {
      HStack {
        Image(systemName: "plus").padding()
        Text("Add a new contact")
      }
      .actionSheet(isPresented: $showingNewContactOptions) {
         ActionSheet(
           title: Text("How do you want to add a new contact?"),
           buttons: [
             .default(Text("Create a new contact")) {
               routeState.navigate(.editContact(contact: nil))
             },
             .default(Text("Import from contacts")) {
               routeState.navigate(.importContact)
             },
             .cancel {
               showingNewContactOptions = false
             }
           ]
         )
       }
    }
  }

  var body: some View {
    NavigationView {
      List {
        SearchBar(search: $search, tokens: $searchTokens)

        if search.count == 0 {
          addNewContact.foregroundColor(Color(UIColor.secondaryLabel))
        }

        MeRow(contacts: contacts)

        ForEach(contacts.filter { filterContact($0) }, id: \Contact.name) { (contact: Contact) in
          BindedContactRow(contact: contact, search: self.$search, searchTokens: self.$searchTokens)
        }
        .onDelete(perform: self.deleteContact)
        .onMove(perform: self.moveContact)
      }
      .resignKeyboardOnDragGesture()
      .navigationBarTitle(Text("Contacts"))
      .navigationBarItems(leading: contacts.count > 0 ? EditButton() : nil, trailing: Button(action: {
        self.showingSheet = true
      }) {
        Image(systemName: "person").padding()
      }
      .actionSheet(isPresented: $showingSheet) {
        ActionSheet(title: Text("Settings"), buttons: [
          .default(Text("Manage Tags"), action: {
            self.routeState.navigate(.tags)
          }),
          .default(Text("Send Feedback"), action: {
            UIApplication.shared.open(App.feedbackPage)
          }),
          .cancel()
        ])
      })

      // default view on iPad
      if contacts.count > 0 {
        ContactDetails(contact: contacts[0]) {
          Button(action: {
            self.routeState.navigate(.editContact(contact: self.contacts[0]))
          }) {
            Text("Edit")
          }
          .padding(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
          .background(Color(UIColor.systemBackground))
          .cornerRadius(5)
        }
      } else {
        VStack {
          Text("Get started by adding a new contact")
          addNewContact.padding(.trailing, 20).foregroundColor(Color.accentColor).border(Color.accentColor)
        }
      }
    }.sheet(isPresented: self.$routeState.isShowingSheetFromList) {
      if self.routeState.isEditing {
        ContactEdition().environment(\.managedObjectContext, self.context).environmentObject(self.routeState)
      } else if self.routeState.isShowingTags {
        Tags().environment(\.managedObjectContext, self.context).environmentObject(self.routeState)
      } else if self.routeState.isImportingContact {
        ContactPicker(delegate: self)
      }
    }

  }

    func hasReceivedContact(contact: Contact?) {
      self.routeState.isShowingSheetFromList = false
      self.routeState.navigate(.editContact(contact: contact))
    }

  private func filterContact(_ contact: Contact) -> Bool {
    guard search.count == 0 || NSPredicate(format: "name contains[c] %@", argumentArray: [search]).evaluate(with: contact) || contact.tags?.first(where: { tag in
      guard let tag = tag as? Tag else {
        return false
      }
      return tag.name?.lowercased().contains(search.lowercased()) ?? false
    }) != nil else {
      return false
    }

    if searchTokens.count == 0 {
      return true
    }

    return searchTokens.allSatisfy { token in
      contact.tags?.first(where: { tag in
        guard let tag = tag as? Tag else {
          return false
        }
        return tag.name?.lowercased() == token.name?.lowercased()
      }) != nil
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
