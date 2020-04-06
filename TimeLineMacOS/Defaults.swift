//
//  Defaults.swift
//  TimeLineMacOS
//
//  Created by Mathieu Dutour on 05/04/2020.
//  Copyright © 2020 Mathieu Dutour. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import Defaults

public final class _DefaultsObservable<Value: Codable>: ObservableObject {
  public let objectWillChange = ObservableObjectPublisher()
  private var observation: DefaultsObservation?
  private let key: Defaults.Key<Value>

  public var value: Value {
    get { Defaults[key] }
    set {
      objectWillChange.send()
      Defaults[key] = newValue
    }
  }

  public init(_ key: Defaults.Key<Value>) {
    self.key = key

    self.observation = Defaults.observe(key, options: [.prior]) { [weak self] change in
      if change.isPrior {
        self?.objectWillChange.send()
      }
    }
  }

  /// Reset the key back to its default value.
  public func reset() {
    Defaults.reset(key)
  }
}

public final class _DefaultsOptionalObservable<Value: Codable>: ObservableObject {
  public let objectWillChange = ObservableObjectPublisher()
  private var observation: DefaultsObservation?
  private let key: Defaults.OptionalKey<Value>

  public var value: Value? {
    get { Defaults[key] }
    set {
      objectWillChange.send()
      Defaults[key] = newValue
    }
  }

  public init(_ key: Defaults.OptionalKey<Value>) {
    self.key = key

    self.observation = Defaults.observe(key, options: [.prior]) { [weak self] change in
      if change.isPrior {
        self?.objectWillChange.send()
      }
    }
  }

  /// Reset the key back to its default value.
  public func reset() {
    Defaults.reset(key)
  }
}

extension Defaults {
  public typealias Observable = _DefaultsObservable
  public typealias OptionalObservable = _DefaultsOptionalObservable

  /**
  Make a Defaults key an observable.
  ```
  struct ContentView: View {
    @ObservedObject var unicorn = Defaults.observable(.unicorn)
  }
  ```
  */
  public static func observable<Value: Codable>(_ key: Defaults.Key<Value>) -> _DefaultsObservable<Value> {
    _DefaultsObservable(key)
  }

  /**
  Make a Defaults optional key an observable.
  ```
  struct ContentView: View {
    @ObservedObject var unicorn = Defaults.observable(.unicorn)
  }
  ```
  */
  public static func observable<Value: Codable>(_ key: Defaults.OptionalKey<Value>) -> _DefaultsOptionalObservable<Value> {
    _DefaultsOptionalObservable(key)
  }
}

@propertyWrapper
public struct Default<Value: Codable>: DynamicProperty {
  @ObservedObject private var observable: Defaults.Observable<Value>

  public init(_ key: Defaults.Key<Value>) {
    self.observable = Defaults.Observable(key)
  }

  public var wrappedValue: Value {
    get { observable.value }
    nonmutating set {
      observable.value = newValue
    }
  }

  public var projectedValue: Binding<Value> { $observable.value }

  public mutating func update() {
    _observable.update()
  }

  /**
  Reset the key back to its default value.
  ```
  struct ContentView: View {
    @Default(.opacity) var opacity
    var body: some View {
      Button("Reset") {
        self._opacity.reset()
      }
    }
  }
  ```
  */
  public func reset() {
    observable.reset()
  }
}

@propertyWrapper
public struct OptionalDefault<Value: Codable>: DynamicProperty {
  @ObservedObject private var observable: Defaults.OptionalObservable<Value>

  public init(_ key: Defaults.OptionalKey<Value>) {
    self.observable = Defaults.OptionalObservable(key)
  }

  public var wrappedValue: Value? {
    get { observable.value }
    nonmutating set {
      observable.value = newValue
    }
  }

  public var projectedValue: Binding<Value?> { $observable.value }

  public mutating func update() {
    _observable.update()
  }

  /**
  Reset the key back to its default value.
  ```
  struct ContentView: View {
    @OptionalDefault(.opacity) var opacity
    var body: some View {
      Button("Reset") {
        self._opacity.reset()
      }
    }
  }
  ```
  */
  public func reset() {
    observable.reset()
  }
}
