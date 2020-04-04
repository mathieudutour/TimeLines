//
//  AppDelegate.swift
//  TimeLineMacOS
//
//  Created by Mathieu Dutour on 04/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Cocoa
import TimeLineSharedMacOS
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var popover = NSPopover()
  var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  var statusBar: StatusBarController?

  func applicationDidFinishLaunching(_ aNotification: Notification) {

    // Get the managed object context from the shared persistent container.
    let context = CoreDataManager.shared.viewContext

    //  Create the SwiftUI view and set the context as the value for the managedObjectContext environment keyPath.
    //  Add `@Environment(\.managedObjectContext)` in the views that will need the context.
    let contentView = MenuView()
      .background(Color.clear)
      .environment(\.managedObjectContext, context)

    let vc = NSHostingController(rootView: contentView)

    popover.contentViewController = vc

    // Create the Status Bar Item with the Popover
    statusBar = StatusBarController(popover, item: statusItem)

    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

}
