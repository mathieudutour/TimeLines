//
//  Utils.swift
//  Time LinesMacOS
//
//  Created by Mathieu Dutour on 05/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Cocoa
import SystemConfiguration
import SwiftUI
import TimeLineSharedMacOS

final class SSMenu: NSMenu, NSMenuDelegate {
  var onOpen: (() -> Void)?
  var onClose: (() -> Void)?
  var onUpdate: ((NSMenu) -> Void)? {
    didSet {
      // Need to update it here, otherwise it's
      // positioned incorrectly on the first open.
      self.onUpdate?(self)
    }
  }

  private(set) var isOpen = false

  override init(title: String) {
    super.init(title: title)
    self.delegate = self
    self.autoenablesItems = false
  }

  @available(*, unavailable)
  required init(coder decoder: NSCoder) {
    fatalError("notYetImplemented")
  }

  func menuWillOpen(_ menu: NSMenu) {
    isOpen = true
    onOpen?()
  }

  func menuDidClose(_ menu: NSMenu) {
    isOpen = false
    onClose?()
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    onUpdate?(menu)
  }
}

extension NSAlert {
  /// Show an alert as a window-modal sheet, or as an app-modal (window-indepedendent) alert if the window is `nil` or not given.
  @discardableResult
  static func showModal(
    for window: NSWindow? = nil,
    message: String,
    informativeText: String? = nil,
    style: Style = .warning
  ) -> NSApplication.ModalResponse {
    NSAlert(
      message: message,
      informativeText: informativeText,
      style: style
    ).runModal(for: window)
  }

  convenience init(
    message: String,
    informativeText: String? = nil,
    style: Style = .warning
  ) {
    self.init()
    self.messageText = message
    self.alertStyle = style

    if let informativeText = informativeText {
      self.informativeText = informativeText
    }
  }

  /// Runs the alert as a window-modal sheet, or as an app-modal (window-indepedendent) alert if the window is `nil` or not given.
  @discardableResult
  func runModal(for window: NSWindow? = nil) -> NSApplication.ModalResponse {
    guard let window = window else {
      return runModal()
    }

    beginSheetModal(for: window) { returnCode in
      NSApp.stopModal(withCode: returnCode)
    }

    return NSApp.runModal(for: window)
  }
}

extension Timer {
  /// Creates a repeating timer that runs for the given `duration`.
  @discardableResult
  open class func scheduledRepeatingTimer(
    withTimeInterval interval: TimeInterval,
    duration: TimeInterval,
    onRepeat: @escaping (Timer) -> Void,
    onFinish: @escaping () -> Void
  ) -> Timer {
    let startDate = Date()

    return Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
      guard Date() <= startDate.addingTimeInterval(duration) else {
        timer.invalidate()
        onFinish()
        return
      }

      onRepeat(timer)
    }
  }
}

extension Collection {
  /**
  Returns a infinite sequence with consecutively unique random elements from the collection.
  ```
  let x = [1, 2, 3].uniqueRandomElementIterator()
  x.next()
  //=> 2
  x.next()
  //=> 1
  for element in x.prefix(2) {
    print(element)
  }
  //=> 3
  //=> 1
  ```
  */
  func uniqueRandomElementIterator() -> AnyIterator<Element> {
    var previousNumber: Int?

    return AnyIterator {
      var offset: Int
      repeat {
        offset = Int.random(in: 0..<self.count)
      } while offset == previousNumber
      previousNumber = offset

      let index = self.index(self.startIndex, offsetBy: offset)
      return self[index]
    }
  }
}

extension NSColor {
  static let systemColors: Set<NSColor> = [
    .systemBlue,
    .systemBrown,
    .systemGray,
    .systemGreen,
    .systemOrange,
    .systemPink,
    .systemPurple,
    .systemRed,
    .systemYellow,
    .systemTeal,
    .systemIndigo
  ]

  private static let uniqueRandomSystemColors = systemColors.uniqueRandomElementIterator()

  static func uniqueRandomSystemColor() -> NSColor {
    uniqueRandomSystemColors.next()!
  }
}

extension Binding where Value: Equatable {
  /**
  Get notified when the binding value changes to a different one.
  Can be useful to manually update non-reactive properties.
  ```
  Toggle(
    "Foo",
    isOn: $foo.onChange {
      bar.isEnabled = $0
    }
  )
  ```
  */
  func onChange(_ action: @escaping (Value) -> Void) -> Self {
    .init(
      get: { self.wrappedValue },
      set: {
        let oldValue = self.wrappedValue
        self.wrappedValue = $0
        let newValue = self.wrappedValue
        if newValue != oldValue {
          action(newValue)
        }
      }
    )
  }

  /**
  Update the given property when the binding value changes to a different one.
  Can be useful to manually update non-reactive properties.
  - Note: Static key paths are not yet supported in Swift: https://forums.swift.org/t/key-path-cannot-refer-to-static-member/28055/2
  ```
  Toggle("Foo", isOn: $foo.onChange(for: bar, keyPath: \.isEnabled))
  ```
  */
  func onChange<Object: AnyObject>(
    for object: Object,
    keyPath: ReferenceWritableKeyPath<Object, Value>
  ) -> Self {
    onChange { [weak object] newValue in
      object?[keyPath: keyPath] = newValue
    }
  }
}


extension Binding {
  /**
  Convert a binding with an optional value to a binding with a non-optional value by using the given default value if the binding value is `nil`.
  ```
  struct ContentView: View {
    private static let defaultInterval = 60.0
    private var interval: Binding<Double> {
      $optionalInterval.withDefaultValue(Self.defaultInterval)
    }
    var body: some View {}
  }
  ```
  */
  func withDefaultValue<T>(_ defaultValue: T) -> Binding<T> where Value == T? {
    .init(
      get: { self.wrappedValue ?? defaultValue },
      set: {
        self.wrappedValue = $0
      }
    )
  }
}


extension Binding {
  /**
  Convert a binding with an optional value to a binding with a boolean value representing whether the original binding value is `nil`.
  - Parameter falseSetValue: The value used when the binding value is set to `false`.
  ```
  struct ContentView: View {
    private static let defaultInterval = 60.0
    private var doesNotHaveInterval: Binding<Bool> {
      $optionalInterval.isNil(falseSetValue: Self.defaultInterval)
    }
    var body: some View {}
  }
  ```
  */
  func isNil<T>(falseSetValue: T) -> Binding<Bool> where Value == T? {
    .init(
      get: { self.wrappedValue == nil },
      set: {
        self.wrappedValue = $0 ? nil : falseSetValue
      }
    )
  }

  /**
  Convert a binding with an optional value to a binding with a boolean value representing whether the original binding value is not `nil`.
  - Parameter trueSetValue: The value used when the binding value is set to `true`.
  ```
  struct ContentView: View {
    private static let defaultInterval = 60.0
    private var hasInterval: Binding<Bool> {
      $optionalInterval.isNotNil(trueSetValue: Self.defaultInterval)
    }
    var body: some View {}
  }
  ```
  */
  func isNotNil<T>(trueSetValue: T) -> Binding<Bool> where Value == T? {
    .init(
      get: { self.wrappedValue != nil },
      set: {
        self.wrappedValue = $0 ? trueSetValue : nil
      }
    )
  }
}

final class CallbackMenuItem: NSMenuItem {
  private static var validateCallback: ((NSMenuItem) -> Bool)?

  static func validate(_ callback: @escaping (NSMenuItem) -> Bool) {
    validateCallback = callback
  }

  init(
    _ title: String,
    key: String = "",
    keyModifiers: NSEvent.ModifierFlags? = nil,
    data: Any? = nil,
    isEnabled: Bool = true,
    isChecked: Bool = false,
    isHidden: Bool = false,
    callback: @escaping (NSMenuItem) -> Void
  ) {
    self.callback = callback
    super.init(title: title, action: #selector(action(_:)), keyEquivalent: key)
    self.target = self
    self.isEnabled = isEnabled
    self.isChecked = isChecked
    self.isHidden = isHidden

    if let keyModifiers = keyModifiers {
      self.keyEquivalentModifierMask = keyModifiers
    }
  }

  @available(*, unavailable)
  required init(coder decoder: NSCoder) {
    fatalError("notYetImplemented")
  }

  private let callback: (NSMenuItem) -> Void

  @objc
  func action(_ sender: NSMenuItem) {
    callback(sender)
  }
}

extension CallbackMenuItem: NSMenuItemValidation {
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    Self.validateCallback?(menuItem) ?? true
  }
}


extension NSMenuItem {
  convenience init(
    _ title: String,
    action: Selector? = nil,
    key: String = "",
    keyModifiers: NSEvent.ModifierFlags? = nil,
    data: Any? = nil,
    isEnabled: Bool = true,
    isChecked: Bool = false,
    isHidden: Bool = false
  ) {
    self.init(title: title, action: action, keyEquivalent: key)
    self.representedObject = data
    self.isEnabled = isEnabled
    self.isChecked = isChecked
    self.isHidden = isHidden

    if let keyModifiers = keyModifiers {
      self.keyEquivalentModifierMask = keyModifiers
    }
  }

  convenience init(
    _ attributedTitle: NSAttributedString,
    action: Selector? = nil,
    key: String = "",
    keyModifiers: NSEvent.ModifierFlags? = nil,
    data: Any? = nil,
    isEnabled: Bool = true,
    isChecked: Bool = false,
    isHidden: Bool = false
  ) {
    self.init(
      "",
      action: action,
      key: key,
      keyModifiers: keyModifiers,
      data: data,
      isEnabled: isEnabled,
      isChecked: isChecked,
      isHidden: isHidden
    )
    self.attributedTitle = attributedTitle
  }

  var isChecked: Bool {
    get { state == .on }
    set {
      state = newValue ? .on : .off
    }
  }
}

extension NSMenu {
  /// Get the `NSMenuItem` that has this menu as a submenu.
  var parentMenuItem: NSMenuItem? {
    guard let supermenu = supermenu else {
      return nil
    }

    let index = supermenu.indexOfItem(withSubmenu: self)
    return supermenu.item(at: index)
  }

  /// Get the item with the given identifier.
  func item(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> NSMenuItem? {
    for item in items where item.identifier == identifier {
      return item
    }

    return nil
  }

  /// Remove the first item in the menu.
  func removeFirstItem() {
    removeItem(at: 0)
  }

  /// Remove the last item in the menu.
  func removeLastItem() {
    removeItem(at: numberOfItems - 1)
  }

  func addSeparator() {
    addItem(.separator())
  }

  @discardableResult
  func add(_ menuItem: NSMenuItem) -> NSMenuItem {
    addItem(menuItem)
    return menuItem
  }

  @discardableResult
  func addDisabled(_ title: String) -> NSMenuItem {
    let menuItem = NSMenuItem(title)
    menuItem.isEnabled = false
    addItem(menuItem)
    return menuItem
  }

  @discardableResult
  func addDisabled(_ attributedTitle: NSAttributedString) -> NSMenuItem {
    let menuItem = NSMenuItem(attributedTitle)
    menuItem.isEnabled = false
    addItem(menuItem)
    return menuItem
  }

  @discardableResult
  func addItem(
    _ title: String,
    action: Selector? = nil,
    key: String = "",
    keyModifiers: NSEvent.ModifierFlags? = nil,
    data: Any? = nil,
    isEnabled: Bool = true,
    isChecked: Bool = false,
    isHidden: Bool = false
  ) -> NSMenuItem {
    let menuItem = NSMenuItem(
      title,
      action: action,
      key: key,
      keyModifiers: keyModifiers,
      data: data,
      isEnabled: isEnabled,
      isChecked: isChecked,
      isHidden: isHidden
    )
    addItem(menuItem)
    return menuItem
  }

  @discardableResult
  func addItem(
    _ attributedTitle: NSAttributedString,
    action: Selector? = nil,
    key: String = "",
    keyModifiers: NSEvent.ModifierFlags? = nil,
    data: Any? = nil,
    isEnabled: Bool = true,
    isChecked: Bool = false,
    isHidden: Bool = false
  ) -> NSMenuItem {
    let menuItem = NSMenuItem(
      attributedTitle,
      action: action,
      key: key,
      keyModifiers: keyModifiers,
      data: data,
      isEnabled: isEnabled,
      isChecked: isChecked,
      isHidden: isHidden
    )
    addItem(menuItem)
    return menuItem
  }

  @discardableResult
  func addCallbackItem(
    _ title: String,
    key: String = "",
    keyModifiers: NSEvent.ModifierFlags? = nil,
    data: Any? = nil,
    isEnabled: Bool = true,
    isChecked: Bool = false,
    isHidden: Bool = false,
    callback: @escaping (NSMenuItem) -> Void
  ) -> NSMenuItem {
    let menuItem = CallbackMenuItem(
      title,
      key: key,
      keyModifiers: keyModifiers,
      data: data,
      isEnabled: isEnabled,
      isChecked: isChecked,
      isHidden: isHidden,
      callback: callback
    )
    addItem(menuItem)
    return menuItem
  }

  @discardableResult
  func addCallbackItem(
    _ title: NSAttributedString,
    key: String = "",
    keyModifiers: NSEvent.ModifierFlags? = nil,
    data: Any? = nil,
    isEnabled: Bool = true,
    isChecked: Bool = false,
    isHidden: Bool = false,
    callback: @escaping (NSMenuItem) -> Void
  ) -> NSMenuItem {
    let menuItem = CallbackMenuItem(
      "",
      key: key,
      keyModifiers: keyModifiers,
      data: data,
      isEnabled: isEnabled,
      isChecked: isChecked,
      isHidden: isHidden,
      callback: callback
    )
    menuItem.attributedTitle = title
    addItem(menuItem)
    return menuItem
  }

  @discardableResult
  func addUrlItem(_ title: String, url: URL) -> NSMenuItem {
    addCallbackItem(title) { _ in
      NSWorkspace.shared.open(url)
    }
  }

  @discardableResult
  func addAboutItem() -> NSMenuItem {
    addCallbackItem("About") {
      NSApp.activate(ignoringOtherApps: true)
      NSApp.orderFrontStandardAboutPanel($0)
    }
  }

  @discardableResult
  func addQuitItem() -> NSMenuItem {
    addSeparator()

    return addCallbackItem("Quit \(App.name)", key: "q") { _ in
      NSApp.terminate(nil)
    }
  }
}
