//
//  VisualEffectView.swift
//  TimeLineSharedMacOS
//
//  Created by Mathieu Dutour on 07/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI

public struct Blur: NSViewRepresentable {
  public var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
  public var material: NSVisualEffectView.Material = .windowBackground

  public init(blendingMode: NSVisualEffectView.BlendingMode = .behindWindow, material: NSVisualEffectView.Material = .windowBackground) {
    self.blendingMode = blendingMode
    self.material = material
  }

  public func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.blendingMode = blendingMode
    view.material = material
    view.state = NSVisualEffectView.State.active
    return view
  }
  public func updateNSView(_ uiView: NSVisualEffectView, context: Context) {
    uiView.blendingMode = blendingMode
    uiView.material = material
  }
}
