//
//  MenuView.swift
//  Time Lines macOS
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
      sortDescriptors: [NSSortDescriptor(keyPath: \Contact.index, ascending: true)],
      predicate: NSPredicate(format: "favorite == YES", argumentArray: [])
  ) var contacts: FetchedResults<Contact>

  var body: some View {
    ZStack {
      List {
        ForEach(contacts, id: \.self) { (contact: Contact) in
          VStack {
            ContactRow(
              name: contact.name ?? "",
              timezone: contact.timeZone,
              coordinate: contact.location,
              startTime: contact.startTime,
              endTime: contact.endTime
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

      VStack {
        HStack {
          Spacer()
          Button(action: {
            guard let delegate = NSApp.delegate as? AppDelegate else {
              return
            }
            delegate.statusBar?.showRightClickMenu(delegate)
          }) {
            Image(nsImage: NSImage(named: NSImage.actionTemplateName)!)
              .colorMultiply(Color(NSColor.secondaryLabelColor))
          }
          .buttonStyle(ButtonThatLookLikeNothingStyle())
          .padding(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
        Spacer()
      }
    }
  }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
