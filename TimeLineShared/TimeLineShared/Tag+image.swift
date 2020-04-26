//
//  Tag+image.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 24/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import SwiftUI

extension Tag {
  public var swiftCircle: some View {
    Circle().foregroundColor(Color(red: self.red, green: self.green, blue: self.blue))
  }

  public static func colorWithHue(_ hue: CGFloat) -> CPColor {
    CPColor(
      hue: hue,
      saturation: 1.0,
      brightness: 1.0,
      alpha: 1.0
    )
  }

  public static func randomColor() -> CPColor {
    Tag.colorWithHue(CGFloat(Double.random(in: 0 ... 359)))
  }
}

#if canImport(UIKit)
import UIKit

public typealias CPColor = UIColor

public extension UIColor {
  var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    return (red, green, blue, alpha)
  }
}

extension Tag {
  public var color: UIColor {
    UIColor(
      red: CGFloat(self.red),
      green: CGFloat(self.green),
      blue: CGFloat(self.blue),
      alpha: 1
    )
  }

  public var image: UIImage {
    UIImage(systemName: "circle.fill")!.withTintColor(self.color, renderingMode: .alwaysOriginal)
  }
}
#elseif canImport(AppKit)
import AppKit

public typealias CPColor = NSColor

public extension NSColor {
  var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    let color = self.usingColorSpace(NSColorSpace.deviceRGB) ?? self
    return (color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
  }
}
#endif
