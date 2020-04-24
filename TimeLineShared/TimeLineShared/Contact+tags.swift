//
//  Contact+tags.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 24/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation

extension Contact {
  public var arrayTags: [Tag] {
    return (self.tags?.allObjects as? [Tag] ?? []).sorted {
      ($0.name?.lowercased() ?? "") < ($1.name?.lowercased() ?? "")
    }
  }
}
