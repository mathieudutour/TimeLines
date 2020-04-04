//
//  StatusBarController.swift
//  TimeLine macOS
//
//  Created by Mathieu Dutour on 04/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import AppKit
import TimeLineSharedMacOS

class StatusBarController {
  private var statusItem: NSStatusItem
  private var popover: NSPopover
  private var statusBarButton: NSStatusBarButton
  private var eventMonitor: EventMonitor?

  init(_ popover: NSPopover, item: NSStatusItem) {
    statusItem = item
    statusBarButton = statusItem.button!
    self.popover = popover

    statusBarButton.image = #imageLiteral(resourceName: "menu-bar")
    statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
    statusBarButton.image?.isTemplate = true
    statusBarButton.toolTip = "TimeLine"

    statusBarButton.action = #selector(togglePopover(sender:))
    statusBarButton.sendAction(on: NSEvent.EventTypeMask.leftMouseUp.union(.rightMouseUp))
    statusBarButton.target = self

    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: mouseEventHandler)
  }

  @objc func togglePopover(sender: AnyObject) {
    if let event = NSApplication.shared.currentEvent, event.modifierFlags.contains(.control) || event.type == .rightMouseUp {
      // Handle right mouse click
      if popover.isShown {
        hidePopover(sender)
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
    popover.contentSize = NSSize(
      width: 400,
      height: min(CGFloat(CoreDataManager.shared.count() * (80 + 21)), CGFloat((80 + 21) * 5))
    )
    popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
    eventMonitor?.start()
    statusBarButton.cell?.isHighlighted = true
  }

  func hidePopover(_ sender: AnyObject) {
    popover.performClose(sender)
    eventMonitor?.stop()
    statusBarButton.cell?.isHighlighted = false
  }

  func mouseEventHandler(_ event: NSEvent?) {
    if popover.isShown {
      hidePopover(event ?? self)
    }
  }

  func quitMe() {
    NSApplication.shared.terminate(self)
  }
}
