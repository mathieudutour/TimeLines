//
//  StatusBarController.swift
//  Time Lines macOS
//
//  Created by Mathieu Dutour on 04/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import AppKit
import SwiftUI
import TimeLineSharedMacOS

class StatusBarController: NSObject {
  private var statusItem: NSStatusItem
  private var popover: NSPopover
  private var statusBarButton: NSStatusBarButton
  private var eventMonitor: EventMonitor?
  private let menu = SSMenu()
  private var contentView: NSWindowController

  private var showingMenu = false

  init(_ popover: NSPopover, item: NSStatusItem, windowController: NSWindowController) {
    statusItem = item
    contentView = windowController
    statusBarButton = statusItem.button!
    self.popover = popover
    super.init()

    statusItem.behavior = [.removalAllowed, .terminationOnRemoval]
    statusBarButton.image = #imageLiteral(resourceName: "menu-bar")
    statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
    statusBarButton.image?.isTemplate = true
    statusBarButton.toolTip = "Time Lines"

    statusBarButton.action = #selector(togglePopover(sender:))
    statusBarButton.sendAction(on: NSEvent.EventTypeMask.leftMouseUp.union(.rightMouseUp))
    statusBarButton.target = self

    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: mouseEventHandler)

    menu.onUpdate = { _ in
      self.updateMenu()
    }
    menu.delegate = self
  }

  /**
  Quickly cycles through random colors to make a rainbow animation so the user will notice it.
  - Note: It will do nothing if the user has enabled the “Reduce motion” accessibility preference.
  */
  func playRainbowAnimation(duration: TimeInterval = 5) {
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      return
    }

    let originalTintColor = statusBarButton.contentTintColor

    Timer.scheduledRepeatingTimer(
      withTimeInterval: 0.1,
      duration: duration,
      onRepeat: { _ in
        self.statusBarButton.contentTintColor = NSColor.uniqueRandomSystemColor()
      },
      onFinish: {
        self.statusBarButton.contentTintColor = originalTintColor
      }
    )
  }
}

// MARK: Popover
extension StatusBarController {
  @objc func togglePopover(sender: AnyObject) {
    if let event = NSApplication.shared.currentEvent, event.modifierFlags.contains(.control) || event.type == .rightMouseUp {
      // Handle right mouse click
      if popover.isShown {
        hidePopover(sender)
      }

      if showingMenu {
        hideRightClickMenu(sender)
      } else {
        showRightClickMenu(sender)
      }

      return
    }

    // Handle left mouse click
    if popover.isShown {
      hidePopover(sender)
    } else {
      showPopover(sender)
    }
  }

  func showPopover(_ sender: AnyObject) {
    let contacts = CoreDataManager.shared.count()

    // show the manage window when we don't have any contact
    if contacts == 0 {
      self.contentView.showWindow(self)
      return
    }

    let rowSize = 80
    let dividerSize = 29
    popover.contentSize = NSSize(
      width: 400,
      height: max(min(CGFloat(contacts * rowSize + (contacts - 1) * dividerSize), CGFloat(rowSize * 5 + dividerSize * 4)), 50)
    )
    popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
    eventMonitor?.start()
  }

  func hidePopover(_ sender: AnyObject) {
    popover.performClose(sender)
    eventMonitor?.stop()
  }

  func mouseEventHandler(_ event: NSEvent?) {
    if popover.isShown {
      hidePopover(event ?? self)
    }
    if showingMenu {
      hideRightClickMenu(event ?? self)
    }
  }
}

// MARK: right click menu
extension StatusBarController: NSMenuDelegate {
  func showRightClickMenu(_ sender: AnyObject) {
    hidePopover(sender)
    showingMenu = true
    statusItem.menu = menu // add menu to button...
    statusItem.button?.performClick(nil) // ...and click
    eventMonitor?.start()
  }

  func hideRightClickMenu(_ sender: AnyObject) {
    statusItem.menu?.cancelTracking()
  }

  func updateMenu() {
    menu.removeAllItems()

    menu.addCallbackItem("Manage Contacts…", key: ",") { _ in
      self.contentView.showWindow(self)
    }

    menu.addCallbackItem("Restore Purchases") { _ in
      IAPManager.shared.restorePurchases() { _ in }
    }

    let item = menu.addCallbackItem("Start at Login") { menuItem in
      LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
      menuItem.isChecked = LaunchAtLogin.isEnabled
    }
    item.isChecked = LaunchAtLogin.isEnabled

    menu.addSeparator()

    menu.addUrlItem("Send Feedback…", url: App.feedbackPage)

    menu.addQuitItem()
  }

  @objc func menuDidClose(_ menu: NSMenu) {
    showingMenu = false
    statusItem.menu = nil // remove menu so button works as before
    eventMonitor?.stop()
    statusBarButton.cell?.isHighlighted = false
  }
}
