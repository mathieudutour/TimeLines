//
//  TimeZone+print.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 02/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation

public extension TimeZone {
  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }
  
  func diffInSecond() -> Int {
    return self.secondsFromGMT() - TimeZone.autoupdatingCurrent.secondsFromGMT()
  }

  func prettyPrintTimeDiff() -> String {
    let diff = self.diffInSecond()
    let formatter = NumberFormatter()
    formatter.usesSignificantDigits = true
    formatter.minimumSignificantDigits = 1 // default
    formatter.maximumSignificantDigits = 2 // default
    return "\(diff >= 0 ? "+" : "")\(formatter.string(from: NSNumber(value: Double(diff) / 3600)) ?? "")HRS"
  }

  func prettyPrintCurrentTime() -> String {
    return dateFormatter.string(from: Date().addingTimeInterval(TimeInterval(self.diffInSecond())))
  }
}
