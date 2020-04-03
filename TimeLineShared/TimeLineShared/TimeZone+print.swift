//
//  TimeZone+print.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation

public extension TimeZone {
  func diffInSecond() -> Int {
    return self.secondsFromGMT() - TimeZone.autoupdatingCurrent.secondsFromGMT()
  }
  func prettyPrint() -> String {
    let diff = self.diffInSecond()
    let formatter = NumberFormatter()
    formatter.usesSignificantDigits = true
    formatter.minimumSignificantDigits = 1 // default
    formatter.maximumSignificantDigits = 2 // default
    return "\(diff >= 0 ? "+" : "")\(formatter.string(from: NSNumber(value: Double(diff) / 3600)) ?? "")HRS"
  }
}
