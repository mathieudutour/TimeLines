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
  case importContact
  case contact(contact: Contact)
  case tags
  case editTag(tag: Tag?)
}

class RouteState: ObservableObject {
  static let shared = RouteState()

  @Published private(set) var route: Route = .list

  // derived data
  @Published var isShowingSheetFromList: Bool = false {
    didSet {
      if isShowingSheetFromList == oldValue {
        return
      }
      if !isShowingSheetFromList {
        if case .list = route {}
        else {
          navigate(.list)
        }
      }
    }
  }
  @Published var contactDetailed: Contact? = nil {
    didSet {
      if contactDetailed == oldValue {
        return
      }
      if let contact = contactDetailed {
        if case .contact(_) = route {}
        else {
          navigate(.contact(contact: contact))
        }
      } else {
        if case .contact(_) = route {
          navigate(.list)
        }
      }
    }
  }
  @Published var isEditing: Bool = false {
    didSet {
      if isEditing == oldValue {
        return
      }
      if !isEditing, case let .editContact(contact) = route {
        if let contactUnwrap = contact {
          navigate(.contact(contact: contactUnwrap))
        } else {
          navigate(.list)
        }
      }
    }
  }
  @Published var isImportingContact: Bool = false {
      didSet {
          if isImportingContact == oldValue {
            return
          }
          if !isImportingContact, case let .editContact(contact) = route {
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
      if isShowingTags == oldValue {
        return
      }
      if !isShowingTags, case .tags = route {
        navigate(.list)
      }
    }
  }
  @Published var isEditingTag: Bool = false {
    didSet {
      if isEditingTag == oldValue {
        return
      }
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
      contactDetailed = contact
    } else if case let .contact(contact: contact) = route {
      isEditing = false
      editingContact = nil
      isEditingTag = false
      editingTag = nil
      isShowingTags = false
      isShowingSheetFromList = false
      contactDetailed = contact
    } else if case let .editTag(tag: tag) = route {
      isEditing = false
      editingContact = nil
      isEditingTag = true
      editingTag = tag
      isShowingTags = true
      isShowingSheetFromList = true
      contactDetailed = nil
    } else if case .tags = route {
      isEditing = false
      editingContact = nil
      isEditingTag = false
      editingTag = nil
      isShowingTags = true
      isShowingSheetFromList = true
      contactDetailed = nil
    } else if case .importContact = route {
      isEditing = false
      isImportingContact = true
      editingContact = nil
      isEditingTag = false
      editingTag = nil
      isShowingTags = false
      isShowingSheetFromList = true
      contactDetailed = nil
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
