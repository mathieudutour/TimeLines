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
import CoreData

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var iapManager: IAPManager?
  var context: NSManagedObjectContext?

  var popover = NSPopover()
  var windowController = NSWindowController(window: NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
    backing: .buffered,
    defer: false
  ))
  var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  var statusBar: StatusBarController?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    iapManager = IAPManager.shared
    IAPManager.shared.startObserving()

    context = CoreDataManager.shared.viewContext

    let contentView = MenuView()
      .background(Color.clear)
      .environment(\.managedObjectContext, context!)
      .environment(\.inAppPurchaseContext, iapManager!)

    let vc = NSHostingController(rootView: contentView)
    popover.contentViewController = vc

    let manageView = ManageContacts()
      .background(Color.clear)
      .environment(\.managedObjectContext, context!)
      .environment(\.inAppPurchaseContext, iapManager!)

    if let window = windowController.window {
      window.contentView = NSHostingView(rootView: manageView)
      window.setFrameAutosaveName("me.dutour.mathieu.timelinemacos.managecontacts")
      window.title = ""
      window.titlebarAppearsTransparent = true
      window.backgroundColor = NSColor.clear
    }

    // Create the Status Bar Item with the Popover
    statusBar = StatusBarController(popover, item: statusItem, windowController: windowController)

    showWelcomeScreenIfNeeded()
  }

  func showWelcomeScreenIfNeeded() {
    guard App.isFirstLaunch else {
      return
    }

    LaunchAtLogin.isEnabled = true

    NSApp.activate(ignoringOtherApps: true)
    NSAlert.showModal(
      message: "Welcome to TimeLine!",
      informativeText:
        """
        TimeLine lives in the menu bar. Left-click it to see your contacts, right-click to see the options.

        See the project page for what else is planned: https://github.com/mathieudutour/TimeLine/issues
        If you have any feedback, bug reports, or feature requests, kindly use the “Send Feedback” button in the TimeLine menu. We respond to all submissions and reported issues will be dealt with swiftly. It's preferable that you report bugs this way rather than as an App Store review, since the App Store will not allow us to contact you for more information.
        """
    )

    statusBar?.playRainbowAnimation()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

}
