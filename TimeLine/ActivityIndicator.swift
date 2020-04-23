//
//  ActivityIndicator.swift
//  Time Lines
//
//  Created by Mathieu Dutour on 23/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI

// https://stackoverflow.com/a/59056440/2718736

struct ActivityIndicator: UIViewRepresentable {
  public typealias UIView = UIActivityIndicatorView
  var isAnimating: Bool

  var configuration = { (indicator: UIView) in }

  func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
  func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
    isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    configuration(uiView)
  }
}

extension View where Self == ActivityIndicator {
  func configure(_ configuration: @escaping (Self.UIView)->Void) -> Self {
    Self.init(isAnimating: self.isAnimating, configuration: configuration)
  }
}
