//
//  Date+timezone.swift
//  TimeLineShared
//
//  Created by Mathieu Dutour on 23/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation

let cal: Calendar = {
  var _cal = Calendar(identifier: .gregorian)
  _cal.timeZone = TimeZone(identifier: "UTC")!
  return _cal
}()

public extension Date {
  func inTimeZone(_ timezone: TimeZone?) -> Date {
    return self.addingTimeInterval(TimeInterval(timezone?.secondsFromGMT() ?? 0))
  }

  func inTodaysTime(_ date: Date = Date()) -> Date {
    return cal.startOfDay(for: date).addingTimeInterval(self.timeIntervalSince(cal.startOfDay(for: self)))
  }

  static func fractionOfToday(_ fraction: Double) -> Date {
    let time = fraction >= 0 && fraction <= 1 ? 24 * 3600 * fraction : 24 * 3600 * fraction.truncatingRemainder(dividingBy: 1)
    return cal.startOfDay(for: Date()).addingTimeInterval(time)
  }

  func fractionOfToday(_ timezone: TimeZone?) -> Double {
    let inTZ = self.inTimeZone(timezone)
    return inTZ.timeIntervalSince(cal.startOfDay(for: inTZ)) / (3600 * 24)
  }

  func staticTime(_ now: Date, _ timezone: TimeZone?) -> Date {
    return self.inTodaysTime(now.inTimeZone(timezone)).addingTimeInterval(-TimeInterval(timezone?.secondsFromGMT() ?? 0))
  }

  func isToday(_ timezone: TimeZone?) -> Bool {
    return cal.isDateInToday(self.inTimeZone(timezone))
  }

  func isSameDay(_ date: Date, _ timezone: TimeZone?) -> Bool {
    return cal.isDate(self.inTimeZone(timezone), inSameDayAs: date.inTimeZone(timezone))
  }
}
