//
//  Tags.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 26/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import TimeLineShared

struct Tags: View {
  @Environment(\.managedObjectContext) var context
  @EnvironmentObject var routeState: RouteState
  
  @FetchRequest(
      entity: Tag.entity(),
      sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
  ) var tags: FetchedResults<Tag>

  var body: some View {
    NavigationView {
      List {
        Button(action: {
          RouteState.shared.navigate(.editTag(tag: nil))
        }) {
          HStack {
            Image(systemName: "plus").padding()
            Text("Add a new tag")
          }
        }.foregroundColor(Color(UIColor.secondaryLabel))

        ForEach(tags, id: \Tag.name) { (tag: Tag) in
          Button(action: {
            RouteState.shared.navigate(.editTag(tag: tag))
          }) {
            HStack {
              tag.swiftCircle.frame(width: 16, height: 16)
              Text(tag.name ?? "")
              Spacer()
              Text("\(tag.contacts?.count ?? 0) contacts").foregroundColor(Color(UIColor.secondaryLabel))
            }
          }
        }
        .onDelete(perform: self.deleteTag)
      }
      .sheet(isPresented: self.$routeState.isEditingTag) {
        TagEdition().environment(\.managedObjectContext, self.context).environmentObject(self.routeState)
      }
      .navigationBarTitle(Text("Tags"))
      .navigationBarItems(leading: EditButton(), trailing: Button(action: {
          RouteState.shared.navigate(.list)
        }) {
          Text("Cancel")
        }
      )
    }

  }

  func deleteTag(at indexSet: IndexSet) {
    for index in indexSet {
      CoreDataManager.shared.deleteTag(tags[index])
    }
  }
}
