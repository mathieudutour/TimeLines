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
  case tags
  case editTag(tag: Tag?)
}

class RouteState: ObservableObject {
  static let shared = RouteState()

  @Published private(set) var route: Route = .list

  // derived data
  @Published var isShowingSheetFromList: Bool = false  {
     didSet {
       if !isShowingSheetFromList {
         if case .list = route {}
         else {
          navigate(.list)
         }
       }
     }
   }
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
  @Published var isShowingTags: Bool = false {
    didSet {
      if !isShowingTags, case .tags = route {
        navigate(.list)
      }
    }
  }
  @Published var isEditingTag: Bool = false {
    didSet {
      if !isEditingTag, case .editTag(_) = route {
        navigate(.tags)
      }
    }
  }
  @Published private(set) var editingTag: Tag? = nil

  func navigate(_ route: Route) {
    self.route = route
    if case let .editContact(contact) = route {
      isEditing = true
      editingContact = contact
      isEditingTag = false
      editingTag = nil
      isShowingTags = false
      isShowingSheetFromList = true
    } else if case let .editTag(tag: tag) = route {
      isEditing = false
      editingContact = nil
      isEditingTag = true
      editingTag = tag
      isShowingTags = true
      isShowingSheetFromList = true
    } else if case .tags = route {
      isEditing = false
      editingContact = nil
      isEditingTag = false
      editingTag = nil
      isShowingTags = true
      isShowingSheetFromList = true
    } else {
      isEditing = false
      editingContact = nil
      isEditingTag = false
      editingTag = nil
      isShowingTags = false
      isShowingSheetFromList = false
    }
  }
}
