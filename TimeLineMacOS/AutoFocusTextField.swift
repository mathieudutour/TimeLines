//
//  AutoFocusTextField.swift
//  Time LinesMacOS
//
//  Created by Mathieu Dutour on 20/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import AppKit
import MapKit

struct AutoFocusTextField: NSViewRepresentable {
  var placeholder: String?
  @Binding var error: String?
  @Binding var text: String
  @Binding var matchingItems: [MKLocalSearchCompletion]

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeNSView(context: NSViewRepresentableContext<AutoFocusTextField>) -> NSTextField {
    let textField = NSTextField()
    textField.delegate = context.coordinator
    textField.placeholderString = placeholder
    return textField
  }

  func updateNSView(_ uiView: NSTextField, context: NSViewRepresentableContext<AutoFocusTextField>) {
    uiView.stringValue = text
    uiView.placeholderString = placeholder

    if !context.coordinator.didSetFirstResponder, let window = uiView.window, window.firstResponder != uiView {
      context.coordinator.didSetFirstResponder = true
      uiView.becomeFirstResponder()
    }
  }

  class Coordinator: NSObject, NSTextFieldDelegate, MKLocalSearchCompleterDelegate {
    var parent: AutoFocusTextField
    var searchCompleter = MKLocalSearchCompleter()

    var didSetFirstResponder = false

    init(_ autoFocusTextField: AutoFocusTextField) {
      self.parent = autoFocusTextField
      super.init()
      searchCompleter.delegate = self
      searchCompleter.resultTypes = .address
    }

    // MARK: - MKLocalSearchCompleterDelegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
      parent.error = nil
      parent.matchingItems = completer.results
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
      print(error)
      parent.error = error.localizedDescription
    }

    // MARK: - NSTextFieldDelegate
    func controlTextDidChange(_ notification: Notification) {
      if let textField = notification.object as? NSTextField {
        parent.text = textField.stringValue
        if textField.stringValue.count > 0 {
          searchCompleter.queryFragment = textField.stringValue
        } else {
          parent.error = nil
          parent.matchingItems = []
        }
      }
    }
  }
}
