//
//  HostingController.swift
//  TimeLineWatchOS Extension
//
//  Created by Mathieu Dutour on 13/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI
import TimeLineSharedWatchOS
import CoreData

struct WrapperView: View {
  var context: NSManagedObjectContext

  var body: some View {
    ContentView().environment(\.managedObjectContext, context)
  }
}

class HostingController: WKHostingController<WrapperView> {
  let context = CoreDataManager.shared.viewContext

  override var body: WrapperView {
    return WrapperView(context: context)
  }
}
