//
//  AutoFocusTextField.swift
//  TimeLineMacOS
//
//  Created by Mathieu Dutour on 20/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI
import AppKit
import MapKit

struct AutoFocusTextField: NSViewRepresentable {
  var placeholder: String?
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
      parent.matchingItems = completer.results
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
      print(error)
    }

    // MARK: - NSTextFieldDelegate
    func controlTextDidChange(_ notification: Notification) {
      if let textField = notification.object as? NSTextField {
        parent.text = textField.stringValue
        searchCompleter.queryFragment = textField.stringValue
      }
    }
  }
}
