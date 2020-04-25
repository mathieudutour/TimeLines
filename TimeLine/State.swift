//
//  State.swift
//  TimeLine
//
//  Created by Mathieu Dutour on 25/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import Combine
import TimeLineShared

enum Route {
  case list
  case editContact(contact: Contact?)
  case contact(contact: Contact)
}

class RouteState: ObservableObject {
  static let shared = RouteState()

  @Published private(set) var route: Route = .list

  // derived data
  @Published var isEditing: Bool = false {
    didSet {
      if !isEditing, case let .editContact(contact) = route {
        if let contactUnwrap = contact {
          navigate(.contact(contact: contactUnwrap))
        } else {
          navigate(.list)
        }
      }
    }
  }
  @Published private(set) var editingContact: Contact? = nil

  func navigate(_ route: Route) {
    self.route = route
    if case let Route.editContact(contact) = route {
      isEditing = true
      editingContact = contact
    } else {
      isEditing = false
      editingContact = nil
    }
  }

  func isEditingBinding() -> Binding<Bool> {
    Binding<Bool>(
      get: { self.isEditing },
      set: { if !$0 {
        self.navigate(.list)
      }}
    )
  }
}
