//
//  CurrentTime.swift
//  Time Lines Shared
//
//  Created by Mathieu Dutour on 14/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation
import SwiftUI

struct CurrentTimeEnvironmentKey: EnvironmentKey {
  public static let defaultValue = CurrentTime.shared
}

extension EnvironmentValues {
  public var currentTime : CurrentTime {
    set { self[CurrentTimeEnvironmentKey.self] = newValue }
    get { self[CurrentTimeEnvironmentKey.self] }
  }
}

public class CurrentTime: NSObject, ObservableObject {
  public static let shared = CurrentTime()

  @Published public var now: Date = Date()

  private var timer: Timer?
  private var customTime = false

  private override init() {
    super.init()

    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      if !self.customTime {
        self.now = Date()
      }
    }
  }

  deinit {
    timer?.invalidate()
  }

  public func customTime(_ date: Date) {
    self.customTime = true
    self.now = date
  }

  public func releaseCustomTime() {
    self.customTime = false
    self.now = Date()
  }
}
