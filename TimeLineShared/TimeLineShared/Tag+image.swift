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
}

#if canImport(UIKit)
import UIKit

extension Tag {
  public var image: UIImage {
    UIImage(systemName: "circle.fill")!.withTintColor(UIColor(
      red: CGFloat(self.red),
      green: CGFloat(self.green),
      blue: CGFloat(self.blue),
      alpha: 1
    ), renderingMode: .alwaysOriginal)
  }
}
#endif
